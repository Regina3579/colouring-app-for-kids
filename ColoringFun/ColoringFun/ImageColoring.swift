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

    func fill(normalized pt: CGPoint, color: Color, tool: Tool) {
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
            let (r, g, b) = rgb(color)
            for idx in region { let o = idx * 4; paint[o] = r; paint[o+1] = g; paint[o+2] = b; paint[o+3] = 255 }
            if tool == .glitter { addSparkles(region) }
        }

        undoStack.append(changes)
        if undoStack.count > 30 { undoStack.removeFirst() }
        rebuild()
        Haptics.tap()
    }

    private func addSparkles(_ region: [Int]) {
        var rng = SystemRandomNumberGenerator()
        let count = max(8, region.count / 90)
        for _ in 0..<count {
            let idx = region[Int.random(in: 0..<region.count, using: &rng)]
            let o = idx * 4
            paint[o] = 255; paint[o+1] = 255; paint[o+2] = 255; paint[o+3] = 255
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
    let selectedColor: Color
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
                model.fill(normalized: CGPoint(x: u, y: v), color: selectedColor, tool: tool)
            }
        }
    }
}

// MARK: - Full screen for an image page

struct ImageColoringScreen: View {
    let page: ImagePage
    @StateObject private var model: FloodFillModel
    @State private var selectedColor: Color = Palette.swatches[1].color
    @State private var selectedSwatch: UUID = Palette.swatches[1].id
    @State private var tool: Tool = .bucket

    init(page: ImagePage) {
        self.page = page
        _model = StateObject(wrappedValue: FloodFillModel(imageName: page.imageName))
    }

    var body: some View {
        VStack(spacing: 0) {
            ImageColoringCanvas(model: model, selectedColor: selectedColor, tool: tool)
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white, lineWidth: 6))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ToolBar(tool: $tool, onUndo: model.undo, onClear: model.clear)
                .padding(.vertical, 10)

            PaletteBar(selectedColor: $selectedColor, selectedSwatch: $selectedSwatch)
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
