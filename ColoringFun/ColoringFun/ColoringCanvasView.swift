import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Pure drawing of a colouring page with its current fills (no gestures).
/// Reused by the live canvas and by Save/Share image export.
struct ColoringArtwork: View {
    let page: ColoringPage
    let fills: [Int: Fill]

    var body: some View {
        ZStack {
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
            VectorSparkleLayer(page: page, fills: fills)
                .id(fills.values.filter { $0.tool.addsSparkle || $0.paint.sparkles }.count)
        }
        .background(Color.white)
    }

    // MARK: Region rendering

    private func draw(region: Region, in ctx: inout GraphicsContext, layout: Layout) {
        let p = region.path.applying(layout.transform)
        let outline = 3.5 * layout.scale

        if let fill = fills[region.id] {
            let alpha = fill.tool == .crayon ? 0.9 : 1.0
            ctx.fill(p, with: shading(for: fill.paint, in: p.boundingRect, alpha: alpha))
            if fill.tool == .crayon { drawCrayon(p, in: &ctx, layout: layout) }
            if fill.tool.addsSparkle || fill.paint.sparkles {
                let pal = glitterPalettes(for: fill.paint)
                drawGlitter(p, id: region.id, grain: pal.grain,
                            intensity: pal.intensity, big: fill.paint.bigSparkle,
                            in: &ctx, layout: layout)
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
        case .fancy(let style):
            return .linearGradient(Gradient(colors: style.base),
                                   startPoint: CGPoint(x: bbox.minX, y: bbox.minY),
                                   endPoint: CGPoint(x: bbox.maxX, y: bbox.maxY))
        }
    }

    /// Grain palette and density for a paint's static glitter texture.
    private func glitterPalettes(for paint: Paint) -> (grain: [Color], intensity: Double) {
        if let s = paint.fancyStyle {
            return (s.sparkle + [.white, .white], s.intensity)
        }
        let base = paint.colors.first ?? .white
        let gold = Color(red: 1.0, green: 0.86, blue: 0.35)
        return ([.white, .white, blend(base, .white, 0.7), gold, blend(base, .white, 0.25)], 1.0)
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

    /// Static shimmering glitter grains (bright twinkling stars are animated
    /// separately by VectorSparkleLayer).
    private func drawGlitter(_ p: Path, id: Int, grain: [Color],
                             intensity: Double, big: Bool = false,
                             in ctx: inout GraphicsContext, layout: Layout) {
        let b = p.boundingRect
        guard b.width > 0, b.height > 0, !grain.isEmpty else { return }

        // Sparkle styles use bigger round grains (and fewer, so they don't merge).
        let rBase: CGFloat = big ? 1.3 : 0.5
        let rSpan: CGFloat = big ? 3.4 : 1.6
        let density: CGFloat = big ? 520 : 150

        ctx.drawLayer { layer in
            layer.clip(to: p)
            var rng = SeededGenerator(seed: UInt64(bitPattern: Int64(id)) &* 0x9E3779B1 &+ 1)
            let grains = max(60, min(4500, Int(b.width * b.height / density * CGFloat(intensity))))
            for _ in 0..<grains {
                let px = b.minX + CGFloat(rng.unit()) * b.width
                let py = b.minY + CGFloat(rng.unit()) * b.height
                let r = (rBase + CGFloat(rng.unit()) * rSpan) * layout.scale
                let c = grain[Int(rng.unit() * Double(grain.count)) % grain.count]
                layer.fill(Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)),
                           with: .color(c.opacity(0.55 + rng.unit() * 0.45)))
            }
        }
    }

    /// Linear blend between two colours (t = 0 → a, t = 1 → b).
    private func blend(_ a: Color, _ b: Color, _ t: CGFloat) -> Color {
        #if canImport(UIKit)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        UIColor(a).getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        UIColor(b).getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return Color(red: ar + (br - ar) * t, green: ag + (bg - ag) * t, blue: ab + (bb - ab) * t)
        #else
        return a
        #endif
    }
}

/// The interactive drawing surface: the artwork plus zoom/pan and tap-to-fill.
struct ColoringCanvasView: View {
    let page: ColoringPage
    let selectedPaint: Paint
    let tool: Tool

    @Binding var fills: [Int: Fill]
    /// Reports each change (regionID, previousFill, newFill) for undo/redo/replay.
    let onChange: (Int, Fill?, Fill?) -> Void

    var body: some View {
        ColoringArtwork(page: page, fills: fills)
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
        let old = fills[region.id]
        if old == newFill { return }
        onChange(region.id, old, newFill)
        fills[region.id] = newFill
        Haptics.tap()
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
