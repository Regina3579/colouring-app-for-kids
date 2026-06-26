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
    case fill     // paint-bucket flood fill
    case eraser   // rub colour away

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pen:    return "Pen"
        case .brush:  return "Brush"
        case .crayon: return "Crayon"
        case .fill:   return "Fill"
        case .eraser: return "Eraser"
        }
    }

    var emoji: String {
        switch self {
        case .pen:    return "✏️"
        case .brush:  return "🖌️"
        case .crayon: return "🖍️"
        case .fill:   return "🪣"
        case .eraser: return "🧽"
        }
    }

    /// Default stroke width (the eraser uses a chosen size instead).
    var lineWidth: CGFloat {
        switch self {
        case .pen:    return 6
        case .brush:  return 26
        case .crayon: return 16
        default:      return 6
        }
    }

    var tint: Color {
        switch self {
        case .pen:    return Candy.blue
        case .brush:  return Candy.pink
        case .crayon: return Candy.orange
        case .fill:   return Candy.green
        case .eraser: return Candy.teal
        }
    }
}

/// One freehand stroke the child drew.
struct DrawStroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var paint: Paint
    var width: CGFloat
    var tool: DrawTool
}

/// One paint-bucket fill (point is normalized 0…1 in the canvas).
struct FillOp: Equatable {
    var point: CGPoint
    var paint: Paint
}

/// A sticker the child stuck onto the drawing.
struct PlacedSticker: Identifiable, Equatable {
    let id = UUID()
    var symbol: String
    var position: CGPoint
    var scale: CGFloat
    var rotation: Angle
}

/// The cute, attractive sticker catalogue.
enum Stickers {
    static let all: [String] = [
        "⭐️", "🌟", "✨", "💫", "🌈", "🦄", "👑", "🎀",
        "💖", "💕", "💝", "❤️", "💛", "💜", "💙", "💚",
        "🌸", "🌺", "🌼", "🌷", "🌻", "🌹", "🏵️", "🌿",
        "🦋", "🐱", "🐰", "🐻", "🐶", "🐥", "🐞", "🐝",
        "❄️", "☀️", "🌙", "☁️", "🍓", "🍒", "🧁", "🍭",
        "🍩", "🎂", "💎", "🔮", "🍬", "🐢", "🐠", "🌟",
    ]
}

// MARK: - Stroke rendering (shared by live canvas + export)

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

    private static func shading(for paint: Paint, bounds: CGRect) -> GraphicsContext.Shading {
        switch paint {
        case .solid(let c):   return .color(c)
        case .glitter(let c): return .color(c)
        case .gradient(let cs):
            return .linearGradient(Gradient(colors: cs),
                                   startPoint: CGPoint(x: bounds.minX, y: bounds.minY),
                                   endPoint: CGPoint(x: bounds.maxX, y: bounds.maxY))
        case .fancy(let s):
            return .linearGradient(Gradient(colors: s.base),
                                   startPoint: CGPoint(x: bounds.minX, y: bounds.minY),
                                   endPoint: CGPoint(x: bounds.maxX, y: bounds.maxY))
        }
    }

    static func draw(_ stroke: DrawStroke, in ctx: inout GraphicsContext) {
        let path = path(for: stroke)
        let width = stroke.width
        let style = StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)

        if stroke.tool == .eraser {
            if stroke.points.count == 1 { ctx.fill(path, with: .color(.white)) }
            else { ctx.stroke(path, with: .color(.white), style: style) }
            return
        }

        let paintShading = shading(for: stroke.paint, bounds: path.boundingRect)

        if stroke.points.count == 1 {
            ctx.fill(path, with: paintShading)
        } else if stroke.tool == .crayon {
            ctx.stroke(path, with: paintShading, style: style)
            ctx.stroke(path, with: .color(.white.opacity(0.22)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round,
                                          dash: [width * 0.12, width * 0.24]))
        } else {
            ctx.stroke(path, with: paintShading, style: style)
        }

        if stroke.paint.sparkles { drawSparkles(stroke, in: &ctx) }
    }

    private static func drawSparkles(_ stroke: DrawStroke, in ctx: inout GraphicsContext) {
        let colors: [Color]
        switch stroke.paint {
        case .glitter:        colors = [.white]
        case .fancy(let s):   colors = s.sparkle
        default:              return
        }
        var rng = SeededGenerator(seed: UInt64(bitPattern: Int64(stroke.id.hashValue)))
        let w = stroke.width
        for pt in stroke.points where rng.unit() < 0.35 {
            let dx = (rng.unit() - 0.5) * w
            let dy = (rng.unit() - 0.5) * w
            let r = w * (0.06 + rng.unit() * 0.10)
            let c = colors[Int(rng.unit() * Double(colors.count)) % max(colors.count, 1)]
            ctx.fill(Path(ellipseIn: CGRect(x: pt.x + dx - r, y: pt.y + dy - r,
                                            width: r * 2, height: r * 2)),
                     with: .color(c))
        }
    }
}

// MARK: - Paint-bucket flood fill over the freehand strokes

enum FreeFill {
    /// Renders all bucket fills (bounded by the drawn lines) into one image.
    static func render(size: CGSize, strokes: [DrawStroke], ops: [(CGPoint, Paint)]) -> UIImage? {
        guard size.width > 1, size.height > 1, !ops.isEmpty else { return nil }
        let s = min(2.0, 700.0 / max(size.width, size.height))
        let W = max(1, Int(size.width * s)), H = max(1, Int(size.height * s))

        // 1) Barrier bitmap: drawn (non-eraser) lines act as walls.
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.scale = 1; fmt.opaque = true
        let barrierImg = UIGraphicsImageRenderer(size: CGSize(width: W, height: H), format: fmt).image { c in
            let ctx = c.cgContext
            UIColor.white.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
            ctx.setLineCap(.round); ctx.setLineJoin(.round)
            ctx.setStrokeColor(UIColor.black.cgColor)
            ctx.setFillColor(UIColor.black.cgColor)
            for stroke in strokes where stroke.tool != .eraser {
                let pts = stroke.points.map { CGPoint(x: $0.x * s, y: $0.y * s) }
                guard let first = pts.first else { continue }
                if pts.count == 1 {
                    let r = stroke.width * s / 2
                    ctx.fillEllipse(in: CGRect(x: first.x - r, y: first.y - r, width: r * 2, height: r * 2))
                } else {
                    ctx.setLineWidth(max(1, stroke.width * s))
                    ctx.beginPath(); ctx.move(to: first)
                    for p in pts.dropFirst() { ctx.addLine(to: p) }
                    ctx.strokePath()
                }
            }
        }
        guard let cg = barrierImg.cgImage else { return nil }

        var px = [UInt8](repeating: 255, count: W * H * 4)
        px.withUnsafeMutableBytes { raw in
            if let c = CGContext(data: raw.baseAddress, width: W, height: H, bitsPerComponent: 8,
                                 bytesPerRow: W * 4, space: CGColorSpaceCreateDeviceRGB(),
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
                c.draw(cg, in: CGRect(x: 0, y: 0, width: W, height: H))
            }
        }
        var barrier = [Bool](repeating: false, count: W * H)
        for i in 0..<(W * H) {
            let o = i * 4
            let lum = Int(px[o]) * 30 + Int(px[o + 1]) * 59 + Int(px[o + 2]) * 11
            barrier[i] = lum < 12000
        }

        // 2) Flood each fill into an RGBA buffer.
        var fill = [UInt8](repeating: 0, count: W * H * 4)
        var visited = [Bool](repeating: false, count: W * H)
        for (point, paint) in ops {
            for i in visited.indices { visited[i] = false }
            let sx = min(W - 1, max(0, Int(point.x * CGFloat(W))))
            let sy = min(H - 1, max(0, Int(point.y * CGFloat(H))))
            let start = sy * W + sx
            if barrier[start] { continue }
            let (r, g, b) = bytes(paint)
            var stack = [start]; visited[start] = true
            while let i = stack.popLast() {
                let o = i * 4; fill[o] = r; fill[o + 1] = g; fill[o + 2] = b; fill[o + 3] = 255
                let x = i % W, y = i / W
                if x > 0,     !barrier[i - 1], !visited[i - 1] { visited[i - 1] = true; stack.append(i - 1) }
                if x < W - 1, !barrier[i + 1], !visited[i + 1] { visited[i + 1] = true; stack.append(i + 1) }
                if y > 0,     !barrier[i - W], !visited[i - W] { visited[i - W] = true; stack.append(i - W) }
                if y < H - 1, !barrier[i + W], !visited[i + W] { visited[i + W] = true; stack.append(i + W) }
            }
        }

        var out: UIImage?
        fill.withUnsafeMutableBytes { raw in
            if let c = CGContext(data: raw.baseAddress, width: W, height: H, bitsPerComponent: 8,
                                 bytesPerRow: W * 4, space: CGColorSpaceCreateDeviceRGB(),
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
               let img = c.makeImage() {
                out = UIImage(cgImage: img)
            }
        }
        return out
    }

    private static func bytes(_ paint: Paint) -> (UInt8, UInt8, UInt8) {
        let color = paint.colors.first ?? .black
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (UInt8(max(0, min(1, r)) * 255), UInt8(max(0, min(1, g)) * 255), UInt8(max(0, min(1, b)) * 255))
        #else
        return (0, 0, 0)
        #endif
    }
}

/// Base on-screen point size for a sticker at scale 1 (shared by canvas + export).
private let stickerBaseSize: CGFloat = 64

private enum DrawActionKind { case stroke, fill }

/// An undone action kept so it can be redone.
private enum RedoItem {
    case stroke(DrawStroke)
    case fill(FillOp)
}

// MARK: - The blank-canvas drawing screen (Pro)

struct CreateDrawingView: View {
    @State private var strokes: [DrawStroke] = []
    @State private var live: DrawStroke?
    @State private var fillOps: [FillOp] = []
    @State private var fillImage: UIImage?
    @State private var actionLog: [DrawActionKind] = []
    @State private var redoStack: [RedoItem] = []
    @State private var stickers: [PlacedSticker] = []
    @State private var selectedSticker: UUID?
    @State private var showStickers = false
    @State private var tool: DrawTool = .pen
    @State private var selectedPaint: Paint = Palette.defaultPaint
    @State private var selectedSwatchID: String = Palette.defaultID
    @State private var eraserWidth: CGFloat = 34
    @State private var canvasSize: CGSize = .zero
    @State private var didLoad = false
    @State private var isReplaying = false

    @State private var shareItem: ShareItem?
    @State private var savedAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    private let eraserSizes: [CGFloat] = [12, 24, 38, 56, 76]

    private var isEmpty: Bool { strokes.isEmpty && stickers.isEmpty && fillOps.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            canvas
                .allowsHitTesting(!isReplaying)
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white, lineWidth: 6))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            toolRow
                .padding(.vertical, 10)

            if tool == .eraser {
                eraserSizeRow.padding(.bottom, 12)
            } else {
                PaletteBar(selectedPaint: $selectedPaint, selectedSwatchID: $selectedSwatchID)
                    .padding(.bottom, 8)
            }
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
                .disabled(isEmpty || isReplaying)
                Button(action: share) {
                    Image(systemName: "square.and.arrow.up.fill").cuteCircle(Candy.blue)
                }
                .disabled(isEmpty || isReplaying)
            }
        }
        .onDisappear { saveDraft() }
        .sheet(isPresented: $showStickers) {
            StickerPicker { addSticker($0) }
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
            ZStack {
                if let fillImage {
                    Image(uiImage: fillImage)
                        .resizable()
                        .interpolation(.medium)
                        .allowsHitTesting(false)
                }
                Canvas { ctx, _ in
                    for stroke in strokes { DrawingRender.draw(stroke, in: &ctx) }
                    if let live { DrawingRender.draw(live, in: &ctx) }
                }
                .contentShape(Rectangle())
                .gesture(drawGesture)

                ForEach($stickers) { $sticker in
                    StickerView(sticker: $sticker,
                                isSelected: selectedSticker == sticker.id,
                                onSelect: { selectedSticker = sticker.id })
                }

                // Constant-size controls under the selected sticker.
                if let id = selectedSticker, let s = stickers.first(where: { $0.id == id }) {
                    StickerControls(center: s.position,
                                    reach: max(30, s.scale * stickerBaseSize / 2 + 16),
                                    onSmaller: { adjustScale(id, factor: 0.8) },
                                    onBigger: { adjustScale(id, factor: 1.25) },
                                    onDelete: { removeSticker(id) })
                }
            }
            .onAppear { canvasSize = geo.size; loadDraftIfNeeded() }
            .onChange(of: geo.size) { _, new in canvasSize = new; loadDraftIfNeeded() }
            .onChange(of: stickers) { _, _ in saveDraft() }
        }
    }

    private var drawGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !isReplaying else { return }
                if tool == .fill { selectedSticker = nil; return }
                if live == nil {
                    selectedSticker = nil
                    let width = tool == .eraser ? eraserWidth : tool.lineWidth
                    live = DrawStroke(points: [value.location], paint: selectedPaint,
                                      width: width, tool: tool)
                } else {
                    live?.points.append(value.location)
                }
            }
            .onEnded { value in
                guard !isReplaying else { return }
                if tool == .fill { applyFill(at: value.location); return }
                if let finished = live { strokes.append(finished); actionLog.append(.stroke); redoStack.removeAll() }
                live = nil
                Haptics.tap()
                saveDraft()
            }
    }

    // MARK: Tools

    private var toolRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(DrawTool.allCases) { t in
                    Button { tool = t } label: {
                        VStack(spacing: 2) {
                            Text(t.emoji).font(.system(size: 23))
                            Text(t.title).font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 58, height: 58)
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
                    .disabled(isReplaying)
                }

                // Stickers
                Button { showStickers = true } label: {
                    VStack(spacing: 2) {
                        ZStack {
                            Image(systemName: "seal.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white)
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Candy.yellow)
                        }
                        .frame(height: 24)
                        Text("Stickers").font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 66, height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 19).fill(
                            LinearGradient(colors: [Candy.pink, Candy.purple, Candy.blue],
                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .overlay(RoundedRectangle(cornerRadius: 19).stroke(.white, lineWidth: 2))
                    .shadow(color: Candy.purple.opacity(0.45), radius: 3, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(isReplaying)

                roundButton("arrow.uturn.backward", Candy.blue, undo,
                            enabled: !actionLog.isEmpty && !isReplaying)
                roundButton("arrow.uturn.forward", Candy.green, redo,
                            enabled: !redoStack.isEmpty && !isReplaying)
                roundButton("play.fill", Candy.purple, replay,
                            enabled: !strokes.isEmpty && !isReplaying)
                roundButton("trash.fill", Candy.red, clear,
                            enabled: !isEmpty && !isReplaying)
            }
            .padding(.horizontal, 14)
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

    // MARK: Eraser sizes

    private var eraserSizeRow: some View {
        VStack(spacing: 4) {
            Text("Eraser Size")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(Candy.ink.opacity(0.6))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(eraserSizes, id: \.self) { size in
                        let selected = eraserWidth == size
                        Button { eraserWidth = size; Haptics.tap() } label: {
                            ZStack {
                                Circle().fill(.white)
                                Circle().fill(Candy.teal.gradient)
                                    .frame(width: 10 + size * 0.45, height: 10 + size * 0.45)
                            }
                            .frame(width: 54, height: 54)
                            .overlay(Circle().stroke(selected ? Candy.ink : .white,
                                                     lineWidth: selected ? 3 : 2))
                            .scaleEffect(selected ? 1.08 : 1.0)
                            .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                            .animation(.spring(response: 0.3), value: eraserWidth)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: Fill

    private func applyFill(at point: CGPoint) {
        guard !isReplaying, canvasSize.width > 1, canvasSize.height > 1 else { return }
        let p = CGPoint(x: point.x / canvasSize.width, y: point.y / canvasSize.height)
        fillOps.append(FillOp(point: p, paint: selectedPaint))
        actionLog.append(.fill)
        redoStack.removeAll()
        rebuildFill()
        Haptics.tap()
        saveDraft()
    }

    private func rebuildFill() {
        guard !fillOps.isEmpty, canvasSize.width > 1 else { fillImage = nil; return }
        fillImage = FreeFill.render(size: canvasSize, strokes: strokes,
                                    ops: fillOps.map { ($0.point, $0.paint) })
    }

    // MARK: Stickers

    private func addSticker(_ symbol: String) {
        let base = canvasSize == .zero
            ? CGPoint(x: 180, y: 180)
            : CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let k = CGFloat(stickers.count % 6) * 16
        let pos = CGPoint(x: base.x + k - 40, y: base.y + k - 40)
        stickers.append(PlacedSticker(symbol: symbol, position: pos, scale: 1, rotation: .zero))
        selectedSticker = stickers.last?.id
        Haptics.tap()
    }

    private func removeSticker(_ id: UUID) {
        stickers.removeAll { $0.id == id }
        if selectedSticker == id { selectedSticker = nil }
        Haptics.tap()
    }

    private func adjustScale(_ id: UUID, factor: CGFloat) {
        guard let i = stickers.firstIndex(where: { $0.id == id }) else { return }
        stickers[i].scale = min(6, max(0.15, stickers[i].scale * factor))
        Haptics.tap()
    }

    // MARK: Undo / clear / replay

    private func undo() {
        guard let last = actionLog.popLast() else { return }
        switch last {
        case .stroke: if let s = strokes.popLast() { redoStack.append(.stroke(s)) }
        case .fill:   if let f = fillOps.popLast() { redoStack.append(.fill(f)); rebuildFill() }
        }
        Haptics.tap()
        saveDraft()
    }

    private func redo() {
        guard let item = redoStack.popLast() else { return }
        switch item {
        case .stroke(let s): strokes.append(s); actionLog.append(.stroke)
        case .fill(let f):   fillOps.append(f); actionLog.append(.fill); rebuildFill()
        }
        Haptics.tap()
        saveDraft()
    }

    private func clear() {
        guard !isEmpty else { return }
        strokes.removeAll()
        fillOps.removeAll()
        fillImage = nil
        actionLog.removeAll()
        redoStack.removeAll()
        stickers.removeAll()
        selectedSticker = nil
        Haptics.tap()
        saveDraft()
    }

    private func replay() {
        let saved = strokes
        guard !saved.isEmpty, !isReplaying else { return }
        selectedSticker = nil
        isReplaying = true
        strokes = []
        Task { @MainActor in
            for stroke in saved {
                strokes.append(stroke)
                Haptics.tap()
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            isReplaying = false
        }
    }

    // MARK: Persistence

    private func loadDraftIfNeeded() {
        guard !didLoad, canvasSize != .zero else { return }
        didLoad = true
        guard strokes.isEmpty, stickers.isEmpty, fillOps.isEmpty,
              let draft = CanvasDraftStore.shared.load(),
              draft.width > 0, draft.height > 0 else { return }
        let sx = canvasSize.width / draft.width
        let sy = canvasSize.height / draft.height
        strokes = draft.strokes.map { dto in
            DrawStroke(points: dto.pts.map { CGPoint(x: $0[0] * sx, y: $0[1] * sy) },
                       paint: dto.paint.paint, width: dto.w * sx,
                       tool: DrawTool(rawValue: dto.tool) ?? .pen)
        }
        fillOps = (draft.fills ?? []).map { FillOp(point: CGPoint(x: $0.x, y: $0.y), paint: $0.paint.paint) }
        stickers = (draft.stickers ?? []).map { dto in
            PlacedSticker(symbol: dto.symbol,
                          position: CGPoint(x: dto.x * canvasSize.width, y: dto.y * canvasSize.height),
                          scale: CGFloat(dto.scale) * sx, rotation: .radians(dto.rotation))
        }
        actionLog = strokes.map { _ in .stroke } + fillOps.map { _ in .fill }
        rebuildFill()
    }

    private func saveDraft() {
        guard !isReplaying, canvasSize != .zero else { return }
        let dto = CanvasDraft(
            width: Double(canvasSize.width), height: Double(canvasSize.height),
            strokes: strokes.map { stroke in
                CanvasStrokeDTO(pts: stroke.points.map { [Double($0.x), Double($0.y)] },
                                paint: PaintDTO(stroke.paint),
                                w: Double(stroke.width), tool: stroke.tool.rawValue)
            },
            fills: fillOps.map { FillOpDTO(x: Double($0.point.x), y: Double($0.point.y),
                                           paint: PaintDTO($0.paint)) },
            stickers: stickers.map { s in
                StickerDTO(symbol: s.symbol,
                           x: Double(s.position.x / max(canvasSize.width, 1)),
                           y: Double(s.position.y / max(canvasSize.height, 1)),
                           scale: Double(s.scale), rotation: s.rotation.radians)
            })
        CanvasDraftStore.shared.save(dto)
    }

    // MARK: Save / share

    @MainActor private func renderArtwork() -> UIImage? {
        let size = canvasSize == .zero ? CGSize(width: 1000, height: 1000) : canvasSize
        let renderer = ImageRenderer(content:
            DrawArtwork(strokes: strokes, stickers: stickers, fillImage: fillImage, size: size))
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

// MARK: - One sticker (drag to move, pinch to resize, twist to rotate, ✕ to remove)

private struct StickerView: View {
    @Binding var sticker: PlacedSticker
    let isSelected: Bool
    let onSelect: () -> Void

    @GestureState private var drag: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var twist: Angle = .zero

    var body: some View {
        Text(sticker.symbol)
            .font(.system(size: stickerBaseSize))
            .padding(8)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Candy.purple, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                }
            }
            .contentShape(Rectangle())
            .scaleEffect(sticker.scale * pinch)
            .rotationEffect(sticker.rotation + twist)
            .position(x: sticker.position.x + drag.width, y: sticker.position.y + drag.height)
            .gesture(moveScaleRotate)
            .onTapGesture { onSelect() }
    }

    private var moveScaleRotate: some Gesture {
        let d = DragGesture()
            .onChanged { _ in onSelect() }
            .updating($drag) { v, s, _ in s = v.translation }
            .onEnded { v in
                sticker.position.x += v.translation.width
                sticker.position.y += v.translation.height
            }
        let m = MagnifyGesture()
            .updating($pinch) { v, s, _ in s = v.magnification }
            .onEnded { v in sticker.scale = min(6, max(0.15, sticker.scale * v.magnification)) }
        let r = RotateGesture()
            .updating($twist) { v, s, _ in s = v.rotation }
            .onEnded { v in sticker.rotation += v.rotation }
        return d.simultaneously(with: m).simultaneously(with: r)
    }
}

/// Constant-size controls around the selected sticker: ＋ at the top-left,
/// ✕ (close) at the top-right, and − at the bottom-left.
private struct StickerControls: View {
    let center: CGPoint
    let reach: CGFloat        // distance from the centre out to each corner
    let onSmaller: () -> Void
    let onBigger: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack {
            button("plus", Candy.green, onBigger)
                .position(x: center.x - reach, y: center.y - reach)   // top-left
            button("xmark", Candy.red, onDelete)
                .position(x: center.x + reach, y: center.y - reach)   // top-right
            button("minus", Candy.blue, onSmaller)
                .position(x: center.x - reach, y: center.y + reach)   // bottom-left
        }
    }

    private func button(_ symbol: String, _ tint: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Circle().fill(tint.gradient))
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - The sticker picker sheet

private struct StickerPicker: View {
    @Environment(\.dismiss) private var dismiss
    let onPick: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    private let tints: [Color] = [Candy.pink, Candy.blue, Candy.purple, Candy.green, Candy.orange, Candy.teal]

    var body: some View {
        NavigationStack {
            ScrollView {
                Text("Tap a sticker to add it, then drag, pinch and twist it on your drawing!")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Candy.ink.opacity(0.65))
                    .padding(.horizontal, 24)
                    .padding(.top, 6)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(Stickers.all.enumerated()), id: \.offset) { i, symbol in
                        Button { onPick(symbol) } label: {
                            Text(symbol)
                                .font(.system(size: 32))
                                .frame(width: 56, height: 56)
                                .background(tints[i % tints.count].opacity(0.18),
                                            in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white, lineWidth: 2))
                                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
            .background(
                LinearGradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.92),
                                        Color(red: 0.93, green: 0.95, blue: 1.0)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("Stickers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/// Renders the fills, strokes and stickers onto a white page for export/sharing.
struct DrawArtwork: View {
    let strokes: [DrawStroke]
    let stickers: [PlacedSticker]
    let fillImage: UIImage?
    let size: CGSize

    var body: some View {
        Canvas { ctx, sz in
            ctx.fill(Path(CGRect(origin: .zero, size: sz)), with: .color(.white))
            if let fillImage {
                ctx.draw(Image(uiImage: fillImage), in: CGRect(origin: .zero, size: sz))
            }
            for stroke in strokes { DrawingRender.draw(stroke, in: &ctx) }
        }
        .frame(width: size.width, height: size.height)
        .overlay {
            ForEach(stickers) { sticker in
                Text(sticker.symbol)
                    .font(.system(size: stickerBaseSize))
                    .scaleEffect(sticker.scale)
                    .rotationEffect(sticker.rotation)
                    .position(sticker.position)
            }
        }
        .background(Color.white)
    }
}

// MARK: - Persisted draft of the free-draw canvas

struct CanvasStrokeDTO: Codable {
    var pts: [[Double]]
    var paint: PaintDTO
    var w: Double
    var tool: String
}

struct FillOpDTO: Codable {
    var x: Double
    var y: Double
    var paint: PaintDTO
}

struct StickerDTO: Codable {
    var symbol: String
    var x: Double
    var y: Double
    var scale: Double
    var rotation: Double
}

struct CanvasDraft: Codable {
    var width: Double
    var height: Double
    var strokes: [CanvasStrokeDTO]
    var fills: [FillOpDTO]?
    var stickers: [StickerDTO]?
}

/// Persists the in-progress "Create Your Own Drawing" so it survives leaving
/// the screen. Cleared only when the child empties the canvas.
final class CanvasDraftStore {
    static let shared = CanvasDraftStore()
    private let url: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = docs.appendingPathComponent("canvas_draft.json")
    }

    func save(_ draft: CanvasDraft) {
        let noStickers = draft.stickers?.isEmpty ?? true
        let noFills = draft.fills?.isEmpty ?? true
        if draft.strokes.isEmpty && noStickers && noFills {
            try? FileManager.default.removeItem(at: url)
            return
        }
        if let data = try? JSONEncoder().encode(draft) { try? data.write(to: url) }
    }

    func load() -> CanvasDraft? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CanvasDraft.self, from: data)
    }
}
