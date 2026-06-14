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
    @State private var shareImage: UIImage?
    @State private var showShare = false
    @State private var savedAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isReplaying = false

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
                .allowsHitTesting(!isReplaying)
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white, lineWidth: 6))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
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
        .navigationTitle("\(page.emoji) \(page.title)")
        .navigationBarTitleDisplayMode(.inline)
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
                    Image(systemName: "square.and.arrow.down")
                }
                Button(action: share) { Image(systemName: "square.and.arrow.up") }
            }
        }
        .sheet(isPresented: $showShare) {
            if let shareImage { ActivityView(items: [shareImage]) }
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
        let ok = DrawingsStore.shared.save(img)
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
        shareImage = img
        showShare = true
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

    private let blue = Color(red: 0.42, green: 0.55, blue: 0.95)
    private let green = Color(red: 0.30, green: 0.72, blue: 0.45)
    private let red = Color(red: 0.98, green: 0.45, blue: 0.45)

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(Tool.allCases) { t in
                    Button { tool = t } label: {
                        VStack(spacing: 2) {
                            Image(systemName: t.icon).font(.title3)
                            Text(t.title).font(.caption2.bold())
                        }
                        .frame(width: 54, height: 54)
                        .foregroundStyle(tool == t ? .white : Color(red: 0.32, green: 0.30, blue: 0.45))
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(tool == t ? blue : .white)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(isReplaying)
                }

                roundButton("arrow.uturn.backward", blue, onUndo, enabled: canUndo && !isReplaying)
                roundButton("arrow.uturn.forward", blue, onRedo, enabled: canRedo && !isReplaying)
                roundButton("play.fill", green, onReplay, enabled: canReplay && !isReplaying)
                roundButton("trash", red, onClear, enabled: !isReplaying)
            }
            .padding(.horizontal, 14)
        }
    }

    private func roundButton(_ system: String, _ tint: Color, _ action: @escaping () -> Void,
                             enabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(width: 46, height: 54)
                .background(RoundedRectangle(cornerRadius: 15).fill(tint.opacity(enabled ? 1 : 0.35)))
                .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - Colour swatches

struct PaletteBar: View {
    @Binding var selectedPaint: Paint
    @Binding var selectedSwatchID: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(Palette.swatches) { swatch in
                    let selected = selectedSwatchID == swatch.id
                    Button {
                        selectedPaint = swatch.paint
                        selectedSwatchID = swatch.id
                    } label: {
                        SwatchShape(paint: swatch.paint)
                            .frame(width: 46, height: 46)
                            .overlay(Circle().stroke(.white, lineWidth: 4))
                            .overlay(
                                Circle().stroke(Color(red: 0.32, green: 0.30, blue: 0.45),
                                                lineWidth: selected ? 3 : 0)
                                    .padding(-3)
                            )
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
