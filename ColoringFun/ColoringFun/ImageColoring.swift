import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Flood-fill colouring model for real outline images

/// Loads an outline image, treats dark pixels as walls, and floods the
/// enclosed area the child taps with the chosen colour — like a paint bucket.
final class FloodFillModel: ObservableObject {
    let displayImage: UIImage          // crisp line art shown on top
    let aspect: CGFloat                // width / height of the picture

    private let w: Int
    private let h: Int
    private var barrier: [Bool]        // true = outline pixel (a wall)
    private var paint: [UInt8]         // RGBA buffer of the child's colours
    private var visited: [Int32]
    private var gen: Int32 = 0
    private var countable: [Bool] = [] // picture area (excludes outer background)
    private var fillableCount = 0      // number of countable pixels

    /// One recorded fill (for undo / redo / replay).
    struct Op { let point: CGPoint; let paint: Paint; let tool: Tool }
    private var ops: [Op] = []
    private var redoOps: [Op] = []
    /// Called after any edit (fill/undo/redo/clear) — used for auto-save.
    var onStateChange: (() -> Void)?
    var canUndo: Bool { !ops.isEmpty }
    var canRedo: Bool { !redoOps.isEmpty }
    var canReplay: Bool { !ops.isEmpty }

    @Published private(set) var paintImage: UIImage?
    @Published private(set) var hasPaint = false
    /// Animated twinkle anchors over glittered areas (normalized coords).
    @Published private(set) var anchors: [SparkleAnchor] = []

    func currentOps() -> [Op] { ops }

    /// Fraction (0...1) of the picture the child has filled — the outer
    /// background is ignored, so colouring just the character still counts.
    func paintedFraction() -> Double {
        guard fillableCount > 0 else { return 0 }
        var painted = 0
        for idx in 0..<(w * h) where countable[idx] {
            if paint[idx * 4 + 3] > 0 { painted += 1 }
        }
        return Double(painted) / Double(fillableCount)
    }

    /// Restores a saved set of strokes (only if the canvas is currently empty).
    func restore(_ list: [Op]) {
        guard ops.isEmpty, !list.isEmpty else { return }
        for op in list { applyFillRegion(at: op.point, op.paint, op.tool) }
        ops = list
        rebuild()
    }

    init(imageName: String, maxDim: Int = 640, initialOps: [Op] = []) {
        let img = UIImage(named: imageName) ?? FloodFillModel.blank()
        displayImage = img
        aspect = img.size.height > 0 ? img.size.width / img.size.height : 1

        // Rasterise into an RGBA byte buffer we can read (locals only —
        // the closure must not touch self before all members are set).
        let cg = img.cgImage
        var width = cg?.width ?? 1
        var height = cg?.height ?? 1
        let scale = CGFloat(maxDim) / CGFloat(max(width, height))
        if scale < 1 { width = Int(CGFloat(width) * scale); height = Int(CGFloat(height) * scale) }
        let lw = max(width, 1), lh = max(height, 1)

        var pixels = [UInt8](repeating: 255, count: lw * lh * 4)
        pixels.withUnsafeMutableBytes { raw in
            if let ctx = CGContext(data: raw.baseAddress, width: lw, height: lh,
                                   bitsPerComponent: 8, bytesPerRow: lw * 4,
                                   space: CGColorSpaceCreateDeviceRGB(),
                                   bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
               let cg {
                ctx.draw(cg, in: CGRect(x: 0, y: 0, width: lw, height: lh))
            }
        }

        var walls = [Bool](repeating: false, count: lw * lh)
        for i in 0..<(lw * lh) {
            let o = i * 4
            let lum = Int(pixels[o]) * 30 + Int(pixels[o + 1]) * 59 + Int(pixels[o + 2]) * 11
            walls[i] = lum < 11000   // ~110/255 luminance
        }

        // Flood the outer background (anything reachable from the border) so it
        // can be ignored when measuring how "finished" the picture is.
        var background = [Bool](repeating: false, count: lw * lh)
        var stack: [Int] = []
        func seed(_ n: Int) {
            if !walls[n] && !background[n] { background[n] = true; stack.append(n) }
        }
        for x in 0..<lw { seed(x); seed((lh - 1) * lw + x) }
        for y in 0..<lh { seed(y * lw); seed(y * lw + (lw - 1)) }
        while let i = stack.popLast() {
            let x = i % lw, y = i / lw
            if x > 0     { seed(i - 1) }
            if x < lw - 1 { seed(i + 1) }
            if y > 0     { seed(i - lw) }
            if y < lh - 1 { seed(i + lw) }
        }

        // Countable = colourable area that belongs to the picture, not the
        // surrounding background.
        var mask = [Bool](repeating: false, count: lw * lh)
        var fillable = 0
        for i in 0..<(lw * lh) where !walls[i] && !background[i] {
            mask[i] = true; fillable += 1
        }
        fillableCount = fillable

        w = lw
        h = lh
        barrier = walls
        countable = mask
        paint = [UInt8](repeating: 0, count: lw * lh * 4)
        visited = [Int32](repeating: 0, count: lw * lh)

        // Restore a saved drawing's strokes, if provided.
        for op in initialOps { applyFillRegion(at: op.point, op.paint, op.tool) }
        ops = initialOps
        rebuild()
    }

    private static func blank() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100)).image { ctx in
            UIColor.white.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
    }

    /// The finished picture (line art over the child's colours) for Save/Share.
    func exportImage() -> UIImage {
        let size = displayImage.size
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let rect = CGRect(origin: .zero, size: size)
            UIColor.white.setFill(); UIRectFill(rect)
            paintImage?.draw(in: rect)
            displayImage.draw(in: rect, blendMode: .multiply, alpha: 1.0)
        }
    }

    // MARK: Painting

    func fill(normalized pt: CGPoint, paint paintStyle: Paint, tool: Tool) {
        guard applyFillRegion(at: pt, paintStyle, tool) else { return }
        ops.append(Op(point: pt, paint: paintStyle, tool: tool))
        redoOps.removeAll()
        rebuild()
        Haptics.tap()
        onStateChange?()
    }

    /// Paints the region at `pt` with the given paint/tool. Returns false if the
    /// tap missed a fillable area. Does not record undo state.
    @discardableResult
    private func applyFillRegion(at pt: CGPoint, _ paintStyle: Paint, _ tool: Tool) -> Bool {
        let x = min(w - 1, max(0, Int(pt.x * CGFloat(w))))
        let y = min(h - 1, max(0, Int(pt.y * CGFloat(h))))
        let start = y * w + x
        if barrier[start] { return false }                  // tapped a line

        let region = collectRegion(from: start)
        if region.isEmpty { return false }

        if tool == .eraser {
            for idx in region { let o = idx * 4; paint[o] = 0; paint[o+1] = 0; paint[o+2] = 0; paint[o+3] = 0 }
            // Also remove any animated twinkle sparkles sitting in this region,
            // otherwise glitter keeps shimmering over the erased area.
            if !anchors.isEmpty {
                let erased = Set(region)
                anchors.removeAll { a in
                    let ax = min(w - 1, max(0, Int(a.x * CGFloat(w))))
                    let ay = min(h - 1, max(0, Int(a.y * CGFloat(h))))
                    return erased.contains(ay * w + ax)
                }
            }
        } else {
            switch paintStyle {
            case .solid(let color), .glitter(let color):
                let (r, g, b) = rgb(color)
                for idx in region { let o = idx * 4; paint[o] = r; paint[o+1] = g; paint[o+2] = b; paint[o+3] = 255 }
            case .gradient(let colors):
                gradientFill(region, colors)
            case .fancy(let style):
                gradientFill(region, style.base)
            }
            if tool.addsSparkle || paintStyle.sparkles {
                let style = paintStyle.fancyStyle
                let stars: [(UInt8, UInt8, UInt8)] = style.map { $0.sparkle.map { rgb($0) } }
                    ?? [(255, 255, 255), (255, 216, 90)]
                addSparkles(region, tints: sparkleTints(paintStyle), stars: stars,
                            intensity: style?.intensity ?? 1.0)
                addAnchors(region, paint: paintStyle)
            }
            if tool == .crayon { applyCrayonTexture(region) }
        }
        return true
    }

    /// Adds a waxy crayon look: soft diagonal streaks + light grain.
    /// Deterministic, so undo/redo/replay reproduce it exactly.
    private func applyCrayonTexture(_ region: [Int]) {
        func lighten(_ v: UInt8, _ t: Double) -> UInt8 {
            UInt8(min(255, Double(v) + (255 - Double(v)) * t))
        }
        for idx in region {
            let x = idx % w, y = idx / w
            let band = (x + y) % 13
            var light = band < 3 ? 0.24 : (band < 5 ? 0.10 : 0.0)
            let hash = (x &* 73856093) ^ (y &* 19349663)
            if hash & 7 == 0 { light += 0.14 }     // waxy speckle
            if light <= 0 { continue }
            let o = idx * 4
            paint[o] = lighten(paint[o], light)
            paint[o + 1] = lighten(paint[o + 1], light)
            paint[o + 2] = lighten(paint[o + 2], light)
        }
    }

    // MARK: Undo / redo / replay

    func redo() {
        guard let op = redoOps.popLast() else { return }
        applyFillRegion(at: op.point, op.paint, op.tool)
        ops.append(op)
        rebuild()
        Haptics.tap()
        onStateChange?()
    }

    /// Repaints the whole canvas from the given ops (used by undo and replay setup).
    private func rebuildFromOps(_ list: [Op]) {
        for i in paint.indices { paint[i] = 0 }
        anchors.removeAll()
        for op in list { applyFillRegion(at: op.point, op.paint, op.tool) }
    }

    func replayOps() -> [Op] { ops }

    func clearCanvasForReplay() {
        for i in paint.indices { paint[i] = 0 }
        anchors.removeAll()
        rebuild()
    }

    func replayApply(_ op: Op) {
        applyFillRegion(at: op.point, op.paint, op.tool)
        rebuild()
    }

    /// Scatter a handful of animated twinkle anchors across the glittered region.
    private func addAnchors(_ region: [Int], paint paintStyle: Paint) {
        let colors = glitterStarColors(paintStyle)
        let big = paintStyle.bigSparkle
        var rng = SystemRandomNumberGenerator()
        let count = big ? max(4, min(55, region.count / 7500))
                        : max(5, min(70, region.count / 5500))
        for _ in 0..<count {
            let idx = region[Int.random(in: 0..<region.count, using: &rng)]
            let col = colors[Int.random(in: 0..<colors.count, using: &rng)]
            anchors.append(SparkleAnchor(
                x: CGFloat(idx % w) / CGFloat(w),
                y: CGFloat(idx / w) / CGFloat(h),
                color: col,
                size: big ? CGFloat.random(in: 0.013...0.024, using: &rng)
                          : CGFloat.random(in: 0.006...0.013, using: &rng),
                phase: Double.random(in: 0..<6.28, using: &rng)))
        }
    }

    /// Fill a region with a vertical gradient of the given colours.
    private func gradientFill(_ region: [Int], _ colors: [Color]) {
        let stops = colors.map { rgb($0) }
        var minY = Int.max, maxY = Int.min
        for idx in region { let yy = idx / w; if yy < minY { minY = yy }; if yy > maxY { maxY = yy } }
        let span = Double(max(1, maxY - minY))
        for idx in region {
            let t = Double(idx / w - minY) / span
            let (r, g, b) = sample(stops, t)
            let o = idx * 4; paint[o] = r; paint[o+1] = g; paint[o+2] = b; paint[o+3] = 255
        }
    }

    /// Grain colours for the sparkles (tinted for colour glitter, rainbow for holographic).
    private func sparkleTints(_ paint: Paint) -> [(UInt8, UInt8, UInt8)] {
        if let s = paint.fancyStyle {
            return s.sparkle.map { rgb($0) } + [(255, 255, 255), (255, 255, 255)]
        }
        let base = rgb(paint.colors.first ?? .white)
        func toward(_ t: Double) -> (UInt8, UInt8, UInt8) {
            (UInt8(Double(base.0) + (255 - Double(base.0)) * t),
             UInt8(Double(base.1) + (255 - Double(base.1)) * t),
             UInt8(Double(base.2) + (255 - Double(base.2)) * t))
        }
        return [(255, 255, 255), (255, 255, 255), toward(0.7), (255, 216, 90), toward(0.3)]
    }

    /// Linear interpolation across the gradient stops at position t in [0, 1].
    private func sample(_ stops: [(UInt8, UInt8, UInt8)], _ t: Double) -> (UInt8, UInt8, UInt8) {
        if stops.count == 1 { return stops[0] }
        let clamped = min(1, max(0, t))
        let pos = clamped * Double(stops.count - 1)
        let i = min(stops.count - 2, Int(pos))
        let f = pos - Double(i)
        let a = stops[i], b = stops[i + 1]
        func mix(_ x: UInt8, _ y: UInt8) -> UInt8 { UInt8(Double(x) + (Double(y) - Double(x)) * f) }
        return (mix(a.0, b.0), mix(a.1, b.1), mix(a.2, b.2))
    }

    private func addSparkles(_ region: [Int], tints: [(UInt8, UInt8, UInt8)],
                             stars: [(UInt8, UInt8, UInt8)], intensity: Double = 1.0) {
        var rng = SystemRandomNumberGenerator()
        typealias RGB = (UInt8, UInt8, UInt8)
        let white: RGB = (255, 255, 255)
        let grainColors = tints.isEmpty ? [white] : tints
        let starColors = stars.isEmpty ? [white] : stars

        // Only paint pixels belonging to this region (visited == gen), so undo stays exact.
        func setpx(_ x: Int, _ y: Int, _ c: RGB) {
            guard x >= 0, y >= 0, x < w, y < h else { return }
            let idx = y * w + x
            guard visited[idx] == gen else { return }
            let o = idx * 4
            paint[o] = c.0; paint[o+1] = c.1; paint[o+2] = c.2; paint[o+3] = 255
        }
        func block(_ x: Int, _ y: Int, _ s: Int, _ c: RGB) {
            for dy in 0..<s { for dx in 0..<s { setpx(x + dx, y + dy, c) } }
        }
        func sparkle(_ x: Int, _ y: Int, _ L: Int, _ center: RGB) {
            for d in -L...L { setpx(x + d, y, white); setpx(x, y + d, white) }
            let hh = L / 2
            for d in -hh...hh { setpx(x + d, y + d, white); setpx(x + d, y - d, white) }
            setpx(x, y, center)
        }

        // Dense fine grains (2px blocks).
        let grains = max(20, Int(Double(region.count) / 90 * intensity))
        for _ in 0..<grains {
            let idx = region[Int.random(in: 0..<region.count, using: &rng)]
            let c = grainColors[Int.random(in: 0..<grainColors.count, using: &rng)]
            block(idx % w, idx / w, 2, c)
        }
        // A few bright shining star-sparkles with coloured centres.
        let starCount = max(3, Int(Double(region.count) / 3500 * intensity))
        for _ in 0..<starCount {
            let idx = region[Int.random(in: 0..<region.count, using: &rng)]
            let center = starColors[Int.random(in: 0..<starColors.count, using: &rng)]
            sparkle(idx % w, idx / w, 3 + Int.random(in: 0...2, using: &rng), center)
        }
    }

    func undo() {
        guard let op = ops.popLast() else { return }
        redoOps.append(op)
        rebuildFromOps(ops)
        rebuild()
        Haptics.tap()
        onStateChange?()
    }

    func clear() {
        guard hasPaint else { return }
        for i in paint.indices { paint[i] = 0 }
        ops.removeAll()
        redoOps.removeAll()
        anchors.removeAll()
        rebuild()
        Haptics.tap()
        onStateChange?()
    }

    // MARK: Internals

    private func collectRegion(from start: Int) -> [Int] {
        gen &+= 1
        if gen == 0 { visited = [Int32](repeating: 0, count: w * h); gen = 1 }
        var out: [Int] = []
        var stack: [Int] = [start]
        visited[start] = gen
        while let i = stack.popLast() {
            out.append(i)
            let x = i % w, y = i / w
            if x > 0     { push(i - 1, &stack) }
            if x < w - 1 { push(i + 1, &stack) }
            if y > 0     { push(i - w, &stack) }
            if y < h - 1 { push(i + w, &stack) }
        }
        return out
    }

    private func push(_ n: Int, _ stack: inout [Int]) {
        if visited[n] != gen && !barrier[n] { visited[n] = gen; stack.append(n) }
    }

    private func rgb(_ color: Color) -> (UInt8, UInt8, UInt8) {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (UInt8(max(0, min(1, r)) * 255), UInt8(max(0, min(1, g)) * 255), UInt8(max(0, min(1, b)) * 255))
        #else
        return (0, 0, 0)
        #endif
    }

    private func rebuild() {
        hasPaint = !ops.isEmpty
        paint.withUnsafeMutableBytes { raw in
            if let ctx = CGContext(data: raw.baseAddress, width: w, height: h,
                                   bitsPerComponent: 8, bytesPerRow: w * 4,
                                   space: CGColorSpaceCreateDeviceRGB(),
                                   bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
               let cg = ctx.makeImage() {
                paintImage = UIImage(cgImage: cg)
            }
        }
    }
}

// MARK: - The image colouring surface

struct ImageColoringCanvas: View {
    @ObservedObject var model: FloodFillModel
    let selectedPaint: Paint
    let tool: Tool

    var body: some View {
        ZStack {
            Color.white
            if let pimg = model.paintImage {
                Image(uiImage: pimg).resizable().interpolation(.medium)
            }
            Image(uiImage: model.displayImage).resizable().blendMode(.multiply)
            ImageSparkleLayer(anchors: model.anchors)
                .id(model.anchors.count)
        }
        .aspectRatio(model.aspect, contentMode: .fit)
        .zoomableColoring { point, size, scale, offset in
            let fit = aspectFitRect(aspect: model.aspect, in: size)
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let cx = c.x + (point.x - c.x - offset.width) / scale
            let cy = c.y + (point.y - c.y - offset.height) / scale
            let u = (cx - fit.minX) / fit.width
            let v = (cy - fit.minY) / fit.height
            if u >= 0, u <= 1, v >= 0, v <= 1 {
                model.fill(normalized: CGPoint(x: u, y: v), paint: selectedPaint, tool: tool)
            }
        }
    }
}

// MARK: - Full screen for an image page

struct ImageColoringScreen: View {
    let page: ImagePage
    @StateObject private var model: FloodFillModel
    @State private var selectedPaint: Paint = Palette.defaultPaint
    @State private var selectedSwatchID: String = Palette.defaultID
    @State private var tool: Tool = .bucket
    @State private var shareItem: ShareItem?
    @State private var savedAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isReplaying = false
    @State private var celebrating = false

    init(page: ImagePage, initialOps: [FloodFillModel.Op] = []) {
        self.page = page
        _model = StateObject(wrappedValue:
            FloodFillModel(imageName: page.imageName, initialOps: initialOps))
    }

    var body: some View {
        VStack(spacing: 0) {
            ImageColoringCanvas(model: model, selectedPaint: selectedPaint, tool: tool)
                .danceWhenFinished(celebrating)
                .allowsHitTesting(!isReplaying)
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white, lineWidth: 6))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .overlay(alignment: .topTrailing) {
                    DoneTickButton(enabled: model.hasPaint && !isReplaying,
                                   action: startCelebration)
                        .padding(18)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ToolBar(tool: $tool, onUndo: model.undo, onRedo: model.redo,
                    onClear: model.clear, onReplay: replay,
                    canUndo: model.canUndo, canRedo: model.canRedo,
                    canReplay: model.canReplay, isReplaying: isReplaying)
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
            let pageID = page.id
            // Restore this picture's saved progress.
            if model.currentOps().isEmpty, let saved = ProgressStore.shared.load(pageID: pageID) {
                model.restore(saved.floodOps())
            }
            model.onStateChange = { [weak model] in
                guard let model else { return }
                ProgressStore.shared.save(pageID: pageID,
                                          state: .image(pageID: pageID, ops: model.currentOps()))
            }
        }
        .onDisappear {
            ProgressStore.shared.save(pageID: page.id,
                                      state: .image(pageID: page.id, ops: model.currentOps()))
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
                Button { share() } label: {
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

    private func startCelebration() {
        guard !celebrating else { return }
        // The party only starts once most of the picture is coloured in.
        guard model.paintedFraction() >= 0.65 else {
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

    private func replay() {
        let ops = model.replayOps()
        guard !ops.isEmpty, !isReplaying else { return }
        isReplaying = true
        model.clearCanvasForReplay()
        Task { @MainActor in
            for op in ops {
                model.replayApply(op)
                Haptics.tap()
                try? await Task.sleep(nanoseconds: 320_000_000)
            }
            isReplaying = false
        }
    }

    private func saveToDrawings() {
        let state = DrawingState.image(pageID: page.id, ops: model.currentOps())
        let ok = DrawingsStore.shared.save(model.exportImage(), state: state)
        alertTitle = ok ? "Saved!" : "Couldn't Save"
        alertMessage = ok ? "Your drawing was added to My Drawings." : "Something went wrong saving."
        savedAlert = true
    }

    private func saveToPhotos() {
        PhotoSaver.shared.save(model.exportImage()) { ok in
            alertTitle = ok ? "Saved to Photos!" : "Couldn't Save"
            alertMessage = ok ? "Your picture was added to your photos."
                              : "Please allow photo access in Settings to save."
            savedAlert = true
        }
    }

    private func share() {
        shareItem = ShareItem(image: model.exportImage())
    }
}
