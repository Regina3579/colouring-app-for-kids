import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Free-draw tools

/// The tools available on the blank "Create Your Own Drawing" canvas.
enum DrawTool: String, CaseIterable, Identifiable {
    case pen      // thin, crisp line
    case brush    // thick, smooth paintbrush stroke
    case crayon   // waxy, textured stroke
    case eraser   // rub colour away

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pen:    return "Pen"
        case .brush:  return "Brush"
        case .crayon: return "Crayon"
        case .eraser: return "Eraser"
        }
    }

    var emoji: String {
        switch self {
        case .pen:    return "✏️"
        case .brush:  return "🖌️"
        case .crayon: return "🖍️"
        case .eraser: return "🧽"
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .pen:    return 6
        case .brush:  return 26
        case .crayon: return 16
        case .eraser: return 34
        }
    }

    var tint: Color {
        switch self {
        case .pen:    return Candy.blue
        case .brush:  return Candy.pink
        case .crayon: return Candy.orange
        case .eraser: return Candy.teal
        }
    }
}

/// One freehand stroke the child drew.
struct DrawStroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var width: CGFloat
    var tool: DrawTool
}

/// Shared rendering so the live canvas and the exported image look identical.
enum DrawingRender {
    static func path(for stroke: DrawStroke) -> Path {
        var p = Path()
        guard let first = stroke.points.first else { return p }
        if stroke.points.count == 1 {
            let r = stroke.width / 2
            p.addEllipse(in: CGRect(x: first.x - r, y: first.y - r,
                                    width: stroke.width, height: stroke.width))
            return p
        }
        p.move(to: first)
        for pt in stroke.points.dropFirst() { p.addLine(to: pt) }
        return p
    }

    static func draw(_ stroke: DrawStroke, in ctx: inout GraphicsContext) {
        let color = stroke.tool == .eraser ? Color.white : stroke.color
        let path = path(for: stroke)

        // A single tap becomes a round dot.
        if stroke.points.count == 1 {
            let dot = stroke.tool == .crayon ? color.opacity(0.85) : color
            ctx.fill(path, with: .color(dot))
            return
        }

        switch stroke.tool {
        case .pen, .brush, .eraser:
            ctx.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: stroke.width, lineCap: .round, lineJoin: .round))
        case .crayon:
            // Waxy look: a soft base plus a broken, dashed highlight.
            ctx.stroke(path, with: .color(color.opacity(0.85)),
                       style: StrokeStyle(lineWidth: stroke.width, lineCap: .round, lineJoin: .round))
            ctx.stroke(path, with: .color(.white.opacity(0.22)),
                       style: StrokeStyle(lineWidth: stroke.width, lineCap: .round,
                                          dash: [stroke.width * 0.12, stroke.width * 0.24]))
        }
    }
}

// MARK: - The blank-canvas drawing screen (Pro)

struct CreateDrawingView: View {
    @State private var strokes: [DrawStroke] = []
    @State private var live: DrawStroke?
    @State private var tool: DrawTool = .pen
    @State private var colorID: String = "black"
    @State private var canvasSize: CGSize = .zero

    @State private var shareItem: ShareItem?
    @State private var savedAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    /// Solid colours pulled from the shared palette.
    private let palette: [(id: String, color: Color)] = Palette.solids.compactMap {
        if case .solid(let c) = $0.paint { return ($0.id, c) }
        return nil
    }

    private var selectedColor: Color {
        palette.first { $0.id == colorID }?.color ?? .black
    }

    var body: some View {
        VStack(spacing: 0) {
            canvas
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white, lineWidth: 6))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            toolRow
                .padding(.vertical, 10)

            colorRow
                .padding(.bottom, 8)
        }
        .background(
            LinearGradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.86),
                                    Color(red: 0.86, green: 0.95, blue: 1.0)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .navigationTitle("✏️ My Drawing")
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
                    Image(systemName: "tray.and.arrow.down.fill").cuteCircle(Candy.green)
                }
                .disabled(strokes.isEmpty)
                Button(action: share) {
                    Image(systemName: "square.and.arrow.up.fill").cuteCircle(Candy.blue)
                }
                .disabled(strokes.isEmpty)
            }
        }
        .sheet(item: $shareItem) { item in
            ActivityView(items: [item.image])
        }
        .alert(alertTitle, isPresented: $savedAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text(alertMessage) }
    }

    // MARK: Canvas

    private var canvas: some View {
        GeometryReader { geo in
            Canvas { ctx, _ in
                for stroke in strokes { DrawingRender.draw(stroke, in: &ctx) }
                if let live { DrawingRender.draw(live, in: &ctx) }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if live == nil {
                            live = DrawStroke(points: [value.location],
                                              color: selectedColor,
                                              width: tool.lineWidth, tool: tool)
                        } else {
                            live?.points.append(value.location)
                        }
                    }
                    .onEnded { _ in
                        if let finished = live { strokes.append(finished) }
                        live = nil
                        Haptics.tap()
                    }
            )
            .onAppear { canvasSize = geo.size }
            .onChange(of: geo.size) { _, new in canvasSize = new }
        }
    }

    // MARK: Tools

    private var toolRow: some View {
        HStack(spacing: 12) {
            ForEach(DrawTool.allCases) { t in
                Button { tool = t } label: {
                    VStack(spacing: 2) {
                        Text(t.emoji).font(.system(size: 24))
                        Text(t.title).font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 62, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 19)
                            .fill(t.tint.gradient)
                            .overlay(RoundedRectangle(cornerRadius: 19)
                                .fill(.white.opacity(tool == t ? 0 : 0.22)))
                    )
                    .overlay(RoundedRectangle(cornerRadius: 19)
                        .stroke(.white, lineWidth: tool == t ? 4 : 2))
                    .scaleEffect(tool == t ? 1.1 : 1.0)
                    .shadow(color: t.tint.opacity(0.45), radius: 3, y: 2)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: tool)
                }
                .buttonStyle(.plain)
            }

            roundButton("arrow.uturn.backward", Candy.blue, undo, enabled: !strokes.isEmpty)
            roundButton("trash.fill", Candy.red, clear, enabled: !strokes.isEmpty)
        }
    }

    private func roundButton(_ system: String, _ tint: Color,
                             _ action: @escaping () -> Void, enabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Circle().fill((enabled ? tint : Color.gray.opacity(0.4)).gradient))
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .shadow(color: (enabled ? tint : .clear).opacity(0.45), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: Colours

    private var colorRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(palette, id: \.id) { item in
                    let selected = colorID == item.id
                    Button {
                        colorID = item.id
                        if tool == .eraser { tool = .pen }   // picking a colour leaves the eraser
                    } label: {
                        Circle().fill(item.color)
                            .frame(width: 46, height: 46)
                            .overlay(Circle().stroke(.white, lineWidth: 4))
                            .overlay(Circle().stroke(Candy.ink, lineWidth: selected ? 3 : 0).padding(-3))
                            .scaleEffect(selected ? 1.18 : 1.0)
                            .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                            .animation(.spring(response: 0.3), value: colorID)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
        }
    }

    // MARK: Actions

    private func undo() {
        guard !strokes.isEmpty else { return }
        strokes.removeLast()
        Haptics.tap()
    }

    private func clear() {
        guard !strokes.isEmpty else { return }
        strokes.removeAll()
        Haptics.tap()
    }

    @MainActor private func renderArtwork() -> UIImage? {
        let size = canvasSize == .zero ? CGSize(width: 1000, height: 1000) : canvasSize
        let renderer = ImageRenderer(content: DrawArtwork(strokes: strokes, size: size))
        renderer.scale = max(UIScreen.main.scale, 2) * 1.5
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
        shareItem = ShareItem(image: img)
    }
}

/// Renders the strokes onto a white page for export/sharing.
struct DrawArtwork: View {
    let strokes: [DrawStroke]
    let size: CGSize

    var body: some View {
        Canvas { ctx, sz in
            ctx.fill(Path(CGRect(origin: .zero, size: sz)), with: .color(.white))
            for stroke in strokes { DrawingRender.draw(stroke, in: &ctx) }
        }
        .frame(width: size.width, height: size.height)
        .background(Color.white)
    }
}
