import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// The drawing surface: renders every region and fills the one the child
/// touches with the currently selected colour + tool.
struct ColoringCanvasView: View {
    let page: ColoringPage
    let selectedPaint: Paint
    let tool: Tool

    @Binding var fills: [Int: Fill]
    /// Records (regionID, previousFill) so a single Undo can step back.
    @Binding var history: [(Int, Fill?)]

    var body: some View {
        Canvas { ctx, size in
            let layout = Layout(canvas: page.canvas, view: size)
            for region in page.regions {
                draw(region: region, in: &ctx, layout: layout)
            }
            if let deco = page.decorations {
                let p = deco.applying(layout.transform)
                ctx.stroke(p, with: .color(.black),
                           style: StrokeStyle(lineWidth: 3 * layout.scale,
                                              lineCap: .round, lineJoin: .round))
            }
        }
        .background(Color.white)
        .zoomableColoring { point, size, scale, offset in
            fill(at: point, size: size, scale: scale, offset: offset)
        }
    }

    // MARK: Painting

    private func fill(at point: CGPoint, size: CGSize, scale: CGFloat, offset: CGSize) {
        let layout = Layout(canvas: page.canvas, view: size)
        let c = CGPoint(x: size.width / 2, y: size.height / 2)
        let pc = CGPoint(x: c.x + (point.x - c.x - offset.width) / scale,
                         y: c.y + (point.y - c.y - offset.height) / scale)
        guard let design = layout.toDesign(pc) else { return }
        guard let region = page.regions.last(where: { $0.path.contains(design) }) else { return }
        let newFill: Fill? = (tool == .eraser) ? nil : Fill(paint: selectedPaint, tool: tool)
        if fills[region.id] == newFill { return }
        history.append((region.id, fills[region.id]))
        if history.count > 50 { history.removeFirst() }
        fills[region.id] = newFill
        Haptics.tap()
    }

    // MARK: Region rendering

    private func draw(region: Region, in ctx: inout GraphicsContext, layout: Layout) {
        let p = region.path.applying(layout.transform)
        let outline = 3.5 * layout.scale

        if let fill = fills[region.id] {
            let alpha = fill.tool == .crayon ? 0.9 : 1.0
            ctx.fill(p, with: shading(for: fill.paint, in: p.boundingRect, alpha: alpha))
            if fill.tool == .crayon { drawCrayon(p, in: &ctx, layout: layout) }
            if fill.tool == .glitter || fill.paint.isGlitter {
                drawGlitter(p, id: region.id, in: &ctx, layout: layout)
            }
        } else {
            ctx.fill(p, with: .color(.white))
        }

        ctx.stroke(p, with: .color(.black),
                   style: StrokeStyle(lineWidth: outline, lineCap: .round, lineJoin: .round))
    }

    /// Solid colour or top-to-bottom gradient shading for a region.
    private func shading(for paint: Paint, in bbox: CGRect, alpha: Double) -> GraphicsContext.Shading {
        switch paint {
        case .solid(let color):
            return .color(color.opacity(alpha))
        case .glitter(let color):
            return .color(color.opacity(alpha))
        case .gradient(let colors):
            return .linearGradient(Gradient(colors: colors.map { $0.opacity(alpha) }),
                                   startPoint: CGPoint(x: bbox.midX, y: bbox.minY),
                                   endPoint: CGPoint(x: bbox.midX, y: bbox.maxY))
        }
    }

    /// Waxy crayon look: soft diagonal hatching clipped to the region.
    private func drawCrayon(_ p: Path, in ctx: inout GraphicsContext, layout: Layout) {
        let b = p.boundingRect
        ctx.drawLayer { layer in
            layer.clip(to: p)
            var hatch = Path()
            var x = b.minX - b.height
            let spacing = 16 * layout.scale
            while x < b.maxX + b.height {
                hatch.move(to: CGPoint(x: x, y: b.minY))
                hatch.addLine(to: CGPoint(x: x + b.height, y: b.maxY))
                x += spacing
            }
            layer.stroke(hatch, with: .color(.white.opacity(0.22)),
                         style: StrokeStyle(lineWidth: 7 * layout.scale, lineCap: .round))
        }
    }

    /// Sparkly glitter: scattered stars, stable per region thanks to the seed.
    private func drawGlitter(_ p: Path, id: Int, in ctx: inout GraphicsContext, layout: Layout) {
        let b = p.boundingRect
        guard b.width > 0, b.height > 0 else { return }
        ctx.drawLayer { layer in
            layer.clip(to: p)
            var rng = SeededGenerator(seed: UInt64(bitPattern: Int64(id)) &* 0x9E3779B1 &+ 1)
            let density = max(40, min(700, Int(b.width * b.height / 520)))
            for _ in 0..<density {
                let px = b.minX + CGFloat(rng.unit()) * b.width
                let py = b.minY + CGFloat(rng.unit()) * b.height
                let s = (1.6 + CGFloat(rng.unit()) * 3.2) * layout.scale
                let bright = rng.unit() > 0.5
                let sparkle = star(at: CGPoint(x: px, y: py), size: s)
                layer.fill(sparkle, with: .color(.white.opacity(bright ? 0.95 : 0.5)))
            }
        }
    }

    /// A tiny four-pointed sparkle.
    private func star(at c: CGPoint, size s: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - s))
        p.addLine(to: CGPoint(x: c.x + s * 0.28, y: c.y - s * 0.28))
        p.addLine(to: CGPoint(x: c.x + s, y: c.y))
        p.addLine(to: CGPoint(x: c.x + s * 0.28, y: c.y + s * 0.28))
        p.addLine(to: CGPoint(x: c.x, y: c.y + s))
        p.addLine(to: CGPoint(x: c.x - s * 0.28, y: c.y + s * 0.28))
        p.addLine(to: CGPoint(x: c.x - s, y: c.y))
        p.addLine(to: CGPoint(x: c.x - s * 0.28, y: c.y - s * 0.28))
        p.closeSubpath()
        return p
    }
}

// MARK: - Maps the design canvas into the on-screen view (aspect fit)

struct Layout {
    let scale: CGFloat
    let offset: CGPoint
    let transform: CGAffineTransform

    init(canvas: CGSize, view: CGSize) {
        let s = min(view.width / canvas.width, view.height / canvas.height)
        let ox = (view.width - canvas.width * s) / 2
        let oy = (view.height - canvas.height * s) / 2
        scale = s
        offset = CGPoint(x: ox, y: oy)
        transform = CGAffineTransform(translationX: ox, y: oy).scaledBy(x: s, y: s)
    }

    /// Convert a point in view space back into design space.
    func toDesign(_ pt: CGPoint) -> CGPoint? {
        guard scale > 0 else { return nil }
        return CGPoint(x: (pt.x - offset.x) / scale, y: (pt.y - offset.y) / scale)
    }
}

// MARK: - Gentle haptic feedback when a part is coloured

enum Haptics {
    static func tap() {
        #if canImport(UIKit)
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
        #endif
    }
}
