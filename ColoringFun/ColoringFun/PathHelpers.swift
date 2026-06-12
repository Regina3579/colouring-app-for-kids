import SwiftUI

// MARK: - Shared path builders (design space is 1000 x 1000)

func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
}

func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
}

func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, corner: CGFloat = 0) -> Path {
    Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: corner)
}

func poly(_ pts: [(CGFloat, CGFloat)]) -> Path {
    var p = Path()
    guard let first = pts.first else { return p }
    p.move(to: CGPoint(x: first.0, y: first.1))
    for pt in pts.dropFirst() { p.addLine(to: CGPoint(x: pt.0, y: pt.1)) }
    p.closeSubpath()
    return p
}

/// A rounded petal / leaf ellipse rotated about its own centre.
func leaf(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, angle: CGFloat) -> Path {
    let base = ellipse(cx, cy, rx, ry)
    let t = CGAffineTransform(translationX: cx, y: cy)
        .rotated(by: angle)
        .translatedBy(x: -cx, y: -cy)
    return base.applying(t)
}

/// A smooth closed blob through the given points (Catmull-Rom → Bézier).
/// Great for soft animal bodies, hair and dresses.
func blob(_ pts: [(CGFloat, CGFloat)]) -> Path {
    let p = pts.map { CGPoint(x: $0.0, y: $0.1) }
    var path = Path()
    guard p.count >= 3 else { return poly(pts) }
    let n = p.count
    path.move(to: p[0])
    for i in 0..<n {
        let p0 = p[(i - 1 + n) % n]
        let p1 = p[i]
        let p2 = p[(i + 1) % n]
        let p3 = p[(i + 2) % n]
        let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6.0, y: p1.y + (p2.y - p0.y) / 6.0)
        let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6.0, y: p2.y - (p3.y - p1.y) / 6.0)
        path.addCurve(to: p2, control1: c1, control2: c2)
    }
    path.closeSubpath()
    return path
}

/// A symmetric "bell" gown / dress silhouette from waist down to a curved hem.
func gown(topY: CGFloat, hemY: CGFloat, topHalf: CGFloat, hemHalf: CGFloat,
          cx: CGFloat = 500) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: cx - topHalf, y: topY))
    p.addQuadCurve(to: CGPoint(x: cx - hemHalf, y: hemY),
                   control: CGPoint(x: cx - topHalf - 20, y: (topY + hemY) / 2))
    p.addQuadCurve(to: CGPoint(x: cx + hemHalf, y: hemY),
                   control: CGPoint(x: cx, y: hemY + 70))
    p.addQuadCurve(to: CGPoint(x: cx + topHalf, y: topY),
                   control: CGPoint(x: cx + topHalf + 20, y: (topY + hemY) / 2))
    p.closeSubpath()
    return p
}

// MARK: - Tiny region-list builder used by every page

final class RegionBuilder {
    private(set) var regions: [Region] = []
    private var i = 0
    func add(_ p: Path) { regions.append(Region(id: i, path: p)); i += 1 }
}
