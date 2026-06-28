import SwiftUI

/// One animated sparkle placed over a glittered area (image pages).
struct SparkleAnchor {
    var x: CGFloat        // normalized 0…1 within the picture
    var y: CGFloat
    var color: Color
    var size: CGFloat     // in normalized-ish units (scaled at draw time)
    var phase: Double
}

/// Twinkle brightness in [0, 1] for a sparkle at the given phase and time.
func twinkleLevel(_ time: Double, _ phase: Double) -> Double {
    let v = 0.5 + 0.5 * sin(time * 3.4 + phase)
    return 0.16 + 0.84 * v * v
}

/// A four-pointed sparkle path centred at `c`.
func sparkleStarPath(at c: CGPoint, size s: CGFloat) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: c.x, y: c.y - s))
    p.addLine(to: CGPoint(x: c.x + s * 0.26, y: c.y - s * 0.26))
    p.addLine(to: CGPoint(x: c.x + s, y: c.y))
    p.addLine(to: CGPoint(x: c.x + s * 0.26, y: c.y + s * 0.26))
    p.addLine(to: CGPoint(x: c.x, y: c.y + s))
    p.addLine(to: CGPoint(x: c.x - s * 0.26, y: c.y + s * 0.26))
    p.addLine(to: CGPoint(x: c.x - s, y: c.y))
    p.addLine(to: CGPoint(x: c.x - s * 0.26, y: c.y - s * 0.26))
    p.closeSubpath()
    return p
}

/// Sparkle colours for a paint (rainbow for fancy glitter, tinted otherwise).
func glitterStarColors(_ paint: Paint) -> [Color] {
    if let s = paint.fancyStyle { return s.sparkle + [.white, .white] }
    let base = paint.colors.first ?? .white
    return [.white, .white, Color(red: 1.0, green: 0.86, blue: 0.35), base]
}

/// Draws one twinkling sparkle (soft glow + bright star) at `c`.
func drawTwinkle(_ ctx: inout GraphicsContext, at c: CGPoint, color: Color,
                 size s: CGFloat, level: Double) {
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - s * 1.8, y: c.y - s * 1.8,
                                    width: s * 3.6, height: s * 3.6)),
             with: .radialGradient(Gradient(colors: [color.opacity(0.6 * level), .clear]),
                                   center: c, startRadius: 0, endRadius: s * 1.8))
    let ss = s * (0.65 + 0.55 * level)
    ctx.fill(sparkleStarPath(at: c, size: ss), with: .color(.white.opacity(0.45 + 0.55 * level)))
    ctx.fill(sparkleStarPath(at: c, size: ss * 0.5), with: .color(color.opacity(level)))
}

/// Animated twinkling stars over an image page's glittered areas.
struct ImageSparkleLayer: View {
    let anchors: [SparkleAnchor]

    var body: some View {
        if anchors.isEmpty {
            Color.clear
        } else {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    let unit = min(size.width, size.height)
                    for a in anchors {
                        let c = CGPoint(x: a.x * size.width, y: a.y * size.height)
                        drawTwinkle(&ctx, at: c, color: a.color, size: a.size * unit,
                                    level: twinkleLevel(t, a.phase))
                    }
                }
                .allowsHitTesting(false)
            }
        }
    }
}

/// Animated twinkling stars over the glittered regions of a vector page.
struct VectorSparkleLayer: View {
    let page: ColoringPage
    let fills: [Int: Fill]

    private var hasGlitter: Bool {
        fills.values.contains { $0.tool.addsSparkle || $0.paint.sparkles }
    }

    var body: some View {
        if !hasGlitter {
            Color.clear
        } else {
            TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let layout = Layout(canvas: page.canvas, view: size)
                for region in page.regions {
                    guard let f = fills[region.id], f.tool.addsSparkle || f.paint.sparkles else { continue }
                    let p = region.path.applying(layout.transform)
                    let b = p.boundingRect
                    guard b.width > 0, b.height > 0 else { continue }
                    let colors = glitterStarColors(f.paint)
                    var rng = SeededGenerator(seed: UInt64(bitPattern: Int64(region.id)) &* 2654435761 &+ 7)
                    let count = max(6, min(70, Int(b.width * b.height / 5000)))
                    ctx.drawLayer { layer in
                        layer.clip(to: p)
                        for _ in 0..<count {
                            let px = b.minX + CGFloat(rng.unit()) * b.width
                            let py = b.minY + CGFloat(rng.unit()) * b.height
                            let s = (3.0 + CGFloat(rng.unit()) * 4.5) * layout.scale
                            let phase = rng.unit() * 6.28
                            let col = colors[Int(rng.unit() * Double(colors.count)) % colors.count]
                            drawTwinkle(&layer, at: CGPoint(x: px, y: py), color: col,
                                        size: s, level: twinkleLevel(t, phase))
                        }
                    }
                }
            }
            .allowsHitTesting(false)
            }
        }
    }
}
