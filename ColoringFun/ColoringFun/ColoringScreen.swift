import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// The full colouring experience for one picture: canvas + tools + colours.
struct ColoringScreen: View {
    let page: ColoringPage

    @State private var fills: [Int: Fill] = [:]
    @State private var undoStack: [ColorStep] = []
    @State private var redoStack: [ColorStep] = []
    @State private var selectedPaint: Paint = Palette.defaultPaint
    @State private var selectedSwatchID: String = Palette.defaultID
    @State private var tool: Tool = .bucket
    @State private var shareItem: ShareItem?
    @State private var savedAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isReplaying = false
    @State private var celebrating = false

    init(page: ColoringPage, initialFills: [Int: Fill] = [:]) {
        self.page = page
        let f = initialFills.isEmpty
            ? (ProgressStore.shared.load(pageID: page.id)?.fillsDict() ?? [:])
            : initialFills
        _fills = State(initialValue: f)
    }

    var body: some View {
        VStack(spacing: 0) {
            ColoringCanvasView(page: page,
                               selectedPaint: selectedPaint,
                               tool: tool,
                               fills: $fills,
                               onChange: { id, old, new in
                                   undoStack.append(ColorStep(id: id, old: old, new: new))
                                   redoStack.removeAll()
                               })
                .danceWhenFinished(celebrating)
                .allowsHitTesting(!isReplaying)
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white, lineWidth: 6))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .overlay(alignment: .topTrailing) {
                    DoneTickButton(enabled: !fills.isEmpty && !isReplaying,
                                   action: startCelebration)
                        .padding(18)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ToolBar(tool: $tool, onUndo: undo, onRedo: redo, onClear: clearAll, onReplay: replay,
                    canUndo: !undoStack.isEmpty, canRedo: !redoStack.isEmpty,
                    canReplay: !undoStack.isEmpty, isReplaying: isReplaying)
                .padding(.vertical, 10)

            PaletteBar(selectedPaint: $selectedPaint, selectedSwatchID: $selectedSwatchID)
                .padding(.bottom, 8)
        }
        .background(
            LinearGradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.86),
                                    Color(red: 0.86, green: 0.95, blue: 1.0)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .overlay { if celebrating { CelebrationOverlay() } }
        .navigationTitle("\(page.emoji) \(page.title)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if fills.isEmpty, let saved = ProgressStore.shared.load(pageID: page.id) {
                fills = saved.fillsDict()
            }
        }
        .onChange(of: fills) { _, newFills in
            if !isReplaying {
                ProgressStore.shared.save(pageID: page.id,
                                          state: .vector(pageID: page.id, fills: newFills))
            }
        }
        .onDisappear {
            ProgressStore.shared.save(pageID: page.id,
                                      state: .vector(pageID: page.id, fills: fills))
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button { saveToDrawings() } label: {
                        Label("Save to My Drawings", systemImage: "photo.stack.fill")
                    }
                    Button { saveToPhotos() } label: {
                        Label("Save to Photos", systemImage: "photo")
                    }
                } label: {
                    Image(systemName: "tray.and.arrow.down.fill").cuteCircle(Candy.green)
                }
                Button(action: share) {
                    Image(systemName: "square.and.arrow.up.fill").cuteCircle(Candy.blue)
                }
            }
        }
        .sheet(item: $shareItem) { item in
            ActivityView(items: [item.image])
        }
        .alert(alertTitle, isPresented: $savedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    @MainActor private func renderArtwork() -> UIImage? {
        let w: CGFloat = 1500
        let h = w * page.canvas.height / max(page.canvas.width, 1)
        let renderer = ImageRenderer(content: ColoringArtwork(page: page, fills: fills)
            .frame(width: w, height: h))
        renderer.scale = 2
        return renderer.uiImage
    }

    private func saveToDrawings() {
        guard let img = renderArtwork() else { return }
        let state = DrawingState.vector(pageID: page.id, fills: fills)
        let ok = DrawingsStore.shared.save(img, state: state)
        alertTitle = ok ? "Saved!" : "Couldn't Save"
        alertMessage = ok ? "Your drawing was added to My Drawings." : "Something went wrong saving."
        savedAlert = true
    }

    private func saveToPhotos() {
        guard let img = renderArtwork() else { return }
        PhotoSaver.shared.save(img) { ok in
            alertTitle = ok ? "Saved to Photos!" : "Couldn't Save"
            alertMessage = ok ? "Your picture was added to your photos."
                              : "Please allow photo access in Settings to save."
            savedAlert = true
        }
    }

    private func share() {
        guard let img = renderArtwork() else { return }
        shareItem = ShareItem(image: img)
    }

    private func undo() {
        guard let step = undoStack.popLast() else { return }
        fills[step.id] = step.old
        redoStack.append(step)
        Haptics.tap()
    }

    private func redo() {
        guard let step = redoStack.popLast() else { return }
        fills[step.id] = step.new
        undoStack.append(step)
        Haptics.tap()
    }

    private func clearAll() {
        guard !fills.isEmpty else { return }
        fills = [:]
        undoStack = []
        redoStack = []
        Haptics.tap()
    }

    private func startCelebration() {
        guard !celebrating else { return }
        // The party only starts once most of the picture is coloured in.
        let total = max(page.regions.count, 1)
        guard Double(fills.count) / Double(total) >= 0.65 else {
            alertTitle = "Almost there! 🎨"
            alertMessage = "Colour a little more of your picture, then tap the ✓ to celebrate!"
            savedAlert = true
            return
        }
        celebrating = true
        Haptics.tap()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation { celebrating = false }
        }
    }

    /// Replays the colouring step by step from a blank picture.
    private func replay() {
        let steps = undoStack
        guard !steps.isEmpty, !isReplaying else { return }
        isReplaying = true
        fills = [:]
        Task { @MainActor in
            for step in steps {
                fills[step.id] = step.new
                Haptics.tap()
                try? await Task.sleep(nanoseconds: 320_000_000)
            }
            isReplaying = false
        }
    }
}

/// One colouring step for undo / redo / replay.
struct ColorStep {
    let id: Int
    let old: Fill?
    let new: Fill?
}

// MARK: - Tool buttons + undo / redo / replay / clear

struct ToolBar: View {
    @Binding var tool: Tool
    let onUndo: () -> Void
    var onRedo: () -> Void = {}
    let onClear: () -> Void
    var onReplay: () -> Void = {}
    var canUndo = true
    var canRedo = false
    var canReplay = false
    var isReplaying = false

    @ObservedObject private var pro = ProStore.shared
    @State private var showPro = false

    /// The icon shown on a tool button — a custom picture for Paint, emoji otherwise.
    @ViewBuilder private func toolGlyph(_ t: Tool) -> some View {
        if t == .bucket {
            Image("tool_paint").resizable().scaledToFit().frame(width: 34, height: 34)
        } else if t == .sparkle {
            sparkleWandGlyph
        } else {
            Text(t.emoji).font(.system(size: 24))
        }
    }

    /// A magic wand with a golden star at the tip and little sparkles.
    private var sparkleWandGlyph: some View {
        ZStack {
            // Wand stick (diagonal, bottom-left to top-right).
            Capsule()
                .fill(LinearGradient(colors: [.white, Color(white: 0.8)],
                                     startPoint: .topTrailing, endPoint: .bottomLeading))
                .frame(width: 5, height: 24)
                .rotationEffect(.degrees(42))
                .offset(x: -4, y: 6)
            // Golden star at the top tip.
            Image(systemName: "star.fill")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(LinearGradient(colors: [Candy.yellow, Candy.orange],
                                                startPoint: .top, endPoint: .bottom))
                .shadow(color: .black.opacity(0.15), radius: 1, y: 0.5)
                .offset(x: 8, y: -8)
            // Little sparkles.
            Image(systemName: "sparkle")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
                .offset(x: 9, y: 7)
            Image(systemName: "sparkle")
                .font(.system(size: 5, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .offset(x: -8, y: -5)
        }
        .frame(width: 34, height: 34)
    }

    private func toolColor(_ t: Tool) -> Color {
        switch t {
        case .bucket:  return Candy.blue
        case .crayon:  return Candy.orange
        case .glitter: return Candy.pink
        case .sparkle: return Candy.purple
        case .eraser:  return Candy.teal
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Tool.allCases) { t in
                    let locked = t.isPro && !pro.isUnlocked
                    Button {
                        if locked { showPro = true } else { tool = t }
                    } label: {
                        VStack(spacing: 2) {
                            toolGlyph(t)
                            Text(t.title).font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 58, height: 58)
                        .background(
                            RoundedRectangle(cornerRadius: 19)
                                .fill(toolColor(t).gradient)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 19)
                                        .fill(.white.opacity(tool == t ? 0 : 0.22))
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 19)
                                .stroke(.white, lineWidth: tool == t ? 4 : 2)
                        )
                        .overlay(alignment: .topTrailing) {
                            if locked {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(.white)
                                    .padding(3)
                                    .background(Circle().fill(Candy.purple))
                                    .overlay(Circle().stroke(.white, lineWidth: 1))
                                    .offset(x: 4, y: -4)
                            }
                        }
                        .scaleEffect(tool == t ? 1.1 : 1.0)
                        .shadow(color: toolColor(t).opacity(0.45), radius: 3, y: 2)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: tool)
                    }
                    .buttonStyle(.plain)
                    .disabled(isReplaying)
                }

                roundButton("arrow.uturn.backward", Candy.blue, onUndo, enabled: canUndo && !isReplaying)
                roundButton("arrow.uturn.forward", Candy.green, onRedo, enabled: canRedo && !isReplaying)
                roundButton("play.fill", Candy.purple, onReplay, enabled: canReplay && !isReplaying)
                roundButton("trash.fill", Candy.red, onClear, enabled: !isReplaying)
            }
            .padding(.horizontal, 14)
        }
        .sheet(isPresented: $showPro) { ProUnlockView() }
    }

    private func roundButton(_ system: String, _ tint: Color, _ action: @escaping () -> Void,
                             enabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(Circle().fill((enabled ? tint : Color.gray.opacity(0.4)).gradient))
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .shadow(color: (enabled ? tint : .clear).opacity(0.45), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - Colour swatches

struct PaletteBar: View {
    @Binding var selectedPaint: Paint
    @Binding var selectedSwatchID: String
    @ObservedObject private var pro = ProStore.shared
    @State private var showPro = false
    @State private var category: PaletteCategory = .colours

    var body: some View {
        VStack(spacing: 6) {
            categoryTabs

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(category.swatches) { swatch in
                        let selected = selectedSwatchID == swatch.id
                        let locked = swatch.isPro && !pro.isUnlocked
                        Button {
                            if locked {
                                showPro = true
                            } else {
                                selectedPaint = swatch.paint
                                selectedSwatchID = swatch.id
                            }
                        } label: {
                            SwatchShape(paint: swatch.paint)
                                .frame(width: 46, height: 46)
                                .overlay(Circle().stroke(.white, lineWidth: 4))
                                .overlay(
                                    Circle().stroke(Color(red: 0.32, green: 0.30, blue: 0.45),
                                                    lineWidth: selected ? 3 : 0)
                                        .padding(-3)
                                )
                                .overlay(lockBadge(locked))
                                .opacity(locked ? 0.9 : 1)
                                .scaleEffect(selected ? 1.18 : 1.0)
                                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                                .animation(.spring(response: 0.3), value: selectedSwatchID)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $showPro) { ProUnlockView() }
    }

    /// The "Colours / Pastel / Fade / Glitter" tabs above the swatches.
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PaletteCategory.allCases) { cat in
                    let selected = category == cat
                    let locked = cat.isPro && !pro.isUnlocked
                    Button {
                        withAnimation(.spring(response: 0.3)) { category = cat }
                    } label: {
                        HStack(spacing: 4) {
                            Text(cat.emoji).font(.system(size: 14))
                            Text(cat.title).font(.system(size: 13, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(selected ? .white : Candy.ink.opacity(0.75))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().fill(selected ? AnyShapeStyle(Candy.purple.gradient)
                                                    : AnyShapeStyle(Color.white))
                        )
                        .overlay(Capsule().stroke(selected ? Color.clear : Candy.ink.opacity(0.15),
                                                  lineWidth: 1.5))
                        .overlay(alignment: .topTrailing) {
                            if locked {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(.white)
                                    .padding(3)
                                    .background(Circle().fill(Candy.purple))
                                    .overlay(Circle().stroke(.white, lineWidth: 1))
                                    .offset(x: 5, y: -5)
                            }
                        }
                        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)
        }
    }

    @ViewBuilder private func lockBadge(_ locked: Bool) -> some View {
        if locked {
            Image(systemName: "crown.fill")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white)
                .padding(4)
                .background(Circle().fill(Candy.purple))
                .overlay(Circle().stroke(.white, lineWidth: 1.5))
                .offset(x: 16, y: -16)
        }
    }
}

/// A round swatch showing either a solid colour or a gradient blend.
struct SwatchShape: View {
    let paint: Paint

    var body: some View {
        switch paint {
        case .solid(let color):
            Circle().fill(color)
        case .gradient(let colors):
            Circle().fill(LinearGradient(colors: colors,
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
        case .glitter(let color):
            ZStack {
                Circle().fill(color)
                Circle().fill(RadialGradient(colors: [.white.opacity(0.55), .clear],
                                             center: .topLeading, startRadius: 1, endRadius: 34))
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
        case .fancy(let style):
            ZStack {
                Circle().fill(AngularGradient(colors: style.sparkle + [style.sparkle[0]],
                                              center: .center))
                Circle().fill(RadialGradient(colors: [.white.opacity(0.65), .clear],
                                             center: .center, startRadius: 1, endRadius: 26))
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}
