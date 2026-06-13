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
    private var undoStack: [[(Int, (UInt8, UInt8, UInt8, UInt8))]] = []

    @Published private(set) var paintImage: UIImage?
    @Published private(set) var hasPaint = false

    init(imageName: String, maxDim: Int = 640) {
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

        w = lw
        h = lh
        barrier = walls
        paint = [UInt8](repeating: 0, count: lw * lh * 4)
        visited = [Int32](repeating: 0, count: lw * lh)
    }

    private static func blank() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100)).image { ctx in
            UIColor.white.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
    }

    // MARK: Painting

    func fill(normalized pt: CGPoint, paint paintStyle: Paint, tool: Tool) {
        let x = min(w - 1, max(0, Int(pt.x * CGFloat(w))))
        let y = min(h - 1, max(0, Int(pt.y * CGFloat(h))))
        let start = y * w + x
        if barrier[start] { return }                       // tapped a line

        let region = collectRegion(from: start)
        if region.isEmpty { return }

        var changes: [(Int, (UInt8, UInt8, UInt8, UInt8))] = []
        changes.reserveCapacity(region.count)
        for idx in region {
            let o = idx * 4
            changes.append((idx, (paint[o], paint[o + 1], paint[o + 2], paint[o + 3])))
        }

        if tool == .eraser {
            for idx in region { let o = idx * 4; paint[o] = 0; paint[o+1] = 0; paint[o+2] = 0; paint[o+3] = 0 }
        } else {
            switch paintStyle {
            case .solid(let color), .glitter(let color):
                let (r, g, b) = rgb(color)
                for idx in region { let o = idx * 4; paint[o] = r; paint[o+1] = g; paint[o+2] = b; paint[o+3] = 255 }
            case .gradient(let colors):
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
            if tool == .glitter || paintStyle.isGlitter {
                addSparkles(region, base: rgb(paintStyle.colors.first ?? .white))
            }
        }

        undoStack.append(changes)
        if undoStack.count > 30 { undoStack.removeFirst() }
        rebuild()
        Haptics.tap()
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

    private func addSparkles(_ region: [Int], base: (UInt8, UInt8, UInt8)) {
        var rng = SystemRandomNumberGenerator()
        typealias RGB = (UInt8, UInt8, UInt8)
        func toward(_ c: RGB, white t: Double) -> RGB {
            (UInt8(Double(c.0) + (255 - Double(c.0)) * t),
             UInt8(Double(c.1) + (255 - Double(c.1)) * t),
             UInt8(Double(c.2) + (255 - Double(c.2)) * t))
        }
        let white: RGB = (255, 255, 255)
        let gold: RGB = (255, 216, 90)
        let light = toward(base, white: 0.7)
        let deep = toward(base, white: 0.3)
        let tints = [white, white, light, gold, deep]

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
        func sparkle(_ x: Int, _ y: Int, _ L: Int) {
            for d in -L...L { setpx(x + d, y, white); setpx(x, y + d, white) }
            let hh = L / 2
            for d in -hh...hh { setpx(x + d, y + d, white); setpx(x + d, y - d, white) }
            setpx(x, y, gold)
        }

        // Dense fine grains (2px blocks) in tinted colours.
        let grains = max(20, region.count / 90)
        for _ in 0..<grains {
            let idx = region[Int.random(in: 0..<region.count, using: &rng)]
            let c = tints[Int.random(in: 0..<tints.count, using: &rng)]
            block(idx % w, idx / w, 2, c)
        }
        // A few bright shining star-sparkles.
        let stars = max(3, region.count / 3500)
        for _ in 0..<stars {
            let idx = region[Int.random(in: 0..<region.count, using: &rng)]
            sparkle(idx % w, idx / w, 3 + Int.random(in: 0...2, using: &rng))
        }
    }

    func undo() {
        guard let changes = undoStack.popLast() else { return }
        for (idx, old) in changes {
            let o = idx * 4
            paint[o] = old.0; paint[o+1] = old.1; paint[o+2] = old.2; paint[o+3] = old.3
        }
        rebuild()
        Haptics.tap()
    }

    func clear() {
        guard hasPaint else { return }
        for i in paint.indices { paint[i] = 0 }
        undoStack.removeAll()
        rebuild()
        Haptics.tap()
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
        hasPaint = !undoStack.isEmpty
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

    init(page: ImagePage) {
        self.page = page
        _model = StateObject(wrappedValue: FloodFillModel(imageName: page.imageName))
    }

    var body: some View {
        VStack(spacing: 0) {
            ImageColoringCanvas(model: model, selectedPaint: selectedPaint, tool: tool)
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white, lineWidth: 6))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ToolBar(tool: $tool, onUndo: model.undo, onClear: model.clear)
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
    }
}
