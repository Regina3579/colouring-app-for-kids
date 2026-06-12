import SwiftUI

// MARK: - Fairy category (original characters)

enum FairyPages {
    static let all: [ColoringPage] = [bluebell, rosepetal, stardust, twinkle]

    private static func face() -> Path {
        var d = Path()
        d.move(to: CGPoint(x: 472, y: 380))
        d.addQuadCurve(to: CGPoint(x: 528, y: 380), control: CGPoint(x: 500, y: 408))
        d.addEllipse(in: CGRect(x: 434, y: 360, width: 32, height: 20))
        d.addEllipse(in: CGRect(x: 534, y: 360, width: 32, height: 20))
        return d
    }

    /// A magic wand: a thin stick decoration topped with a star region.
    private static func wandDeco(from: CGPoint, to: CGPoint) -> Path {
        var d = Path()
        d.move(to: from); d.addLine(to: to)
        return d
    }

    // Fairy Bluebell — big butterfly wings, short bob, star wand.
    static let bluebell: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(ellipse(300, 360, 150, 170))                              // wing upper
        b.add(ellipse(700, 360, 150, 170))                              // wing upper
        b.add(ellipse(320, 620, 120, 130))                             // wing lower
        b.add(ellipse(680, 620, 120, 130))                             // wing lower
        b.add(gown(topY: 470, hemY: 760, topHalf: 70, hemHalf: 175))     // dress
        b.add(leaf(360, 560, 36, 130, angle: 0.35))                     // arm
        b.add(leaf(660, 540, 36, 150, angle: -0.55))                    // arm (up)
        b.add(rect(470, 430, 60, 55))                                    // neck
        b.add(rect(460, 770, 36, 130, corner: 16))                       // leg
        b.add(rect(504, 770, 36, 130, corner: 16))                       // leg
        b.add(circle(500, 330, 112))                                     // head
        b.add(blob([(392, 300), (400, 200), (500, 175), (600, 200),      // hair bob
                    (608, 320), (560, 250), (500, 244), (440, 250)]))
        b.add(circle(460, 330, 16))                                      // eye
        b.add(circle(540, 330, 16))                                      // eye
        b.add(star5(760, 470, 46))                                       // wand star
        var deco = face()
        deco.addPath(wandDeco(from: CGPoint(x: 690, y: 560), to: CGPoint(x: 752, y: 492)))
        return ColoringPage(id: "bluebell", title: "Bluebell", emoji: "🧚",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions, decorations: deco,
                            cardTint: Color(red: 0.80, green: 0.90, blue: 1.0))
    }()

    // Fairy Rosepetal — flower-petal wings, long hair with a blossom.
    static let rosepetal: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(leaf(310, 380, 120, 150, angle: -0.5))                    // wing
        b.add(leaf(690, 380, 120, 150, angle: 0.5))                     // wing
        b.add(leaf(330, 600, 100, 120, angle: -0.9))                    // wing
        b.add(leaf(670, 600, 100, 120, angle: 0.9))                     // wing
        b.add(blob([(345, 340), (370, 185), (500, 130), (630, 185),      // hair
                    (655, 340), (690, 600), (620, 700), (560, 630),
                    (500, 600), (440, 630), (380, 700), (310, 600)]))
        b.add(gown(topY: 470, hemY: 780, topHalf: 68, hemHalf: 185))     // dress
        b.add(leaf(360, 570, 36, 135, angle: 0.35))                     // arm
        b.add(leaf(640, 570, 36, 135, angle: -0.35))                    // arm
        b.add(rect(470, 430, 60, 58))                                    // neck
        b.add(rect(460, 790, 36, 120, corner: 16))                       // leg
        b.add(rect(504, 790, 36, 120, corner: 16))                       // leg
        b.add(circle(500, 330, 114))                                     // head
        b.add(blob([(390, 300), (400, 205), (500, 180), (600, 205),      // bangs
                    (610, 305), (560, 256), (500, 248), (440, 256)]))
        // blossom in hair (5 petals + centre)
        for k in 0..<5 {
            let a = CGFloat(k) / 5 * .pi * 2
            b.add(circle(615 + cos(a) * 34, 250 + sin(a) * 34, 22))
        }
        b.add(circle(615, 250, 20))                                     // blossom centre
        b.add(circle(460, 330, 16))                                      // eye
        b.add(circle(540, 330, 16))                                      // eye
        return ColoringPage(id: "rosepetal", title: "Rosepetal", emoji: "🧚",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions, decorations: face(),
                            cardTint: Color(red: 1.0, green: 0.84, blue: 0.90))
    }()

    // Fairy Stardust — pointed wings, pigtails, surrounded by stars.
    static let stardust: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(poly([(490, 430), (240, 300), (300, 470), (220, 620), (480, 540)]))  // wing
        b.add(poly([(510, 430), (760, 300), (700, 470), (780, 620), (520, 540)]))  // wing
        b.add(circle(330, 300, 70))                                     // pigtail
        b.add(circle(670, 300, 70))                                     // pigtail
        b.add(gown(topY: 470, hemY: 770, topHalf: 70, hemHalf: 180))     // dress
        b.add(leaf(360, 560, 36, 130, angle: 0.35))                     // arm
        b.add(leaf(640, 560, 36, 130, angle: -0.35))                    // arm
        b.add(rect(470, 430, 60, 55))                                    // neck
        b.add(rect(460, 780, 36, 120, corner: 16))                       // leg
        b.add(rect(504, 780, 36, 120, corner: 16))                       // leg
        b.add(circle(500, 330, 112))                                     // head
        b.add(blob([(392, 300), (400, 200), (500, 175), (600, 200),      // hair
                    (608, 320), (560, 250), (500, 244), (440, 250)]))
        b.add(circle(460, 330, 16))                                      // eye
        b.add(circle(540, 330, 16))                                      // eye
        b.add(star5(180, 760, 42))                                       // star
        b.add(star5(830, 740, 38))                                       // star
        b.add(star5(250, 880, 30))                                       // star
        b.add(star5(760, 880, 34))                                       // star
        return ColoringPage(id: "stardust", title: "Stardust", emoji: "🧚",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions, decorations: face(),
                            cardTint: Color(red: 0.88, green: 0.84, blue: 1.0))
    }()

    // Fairy Twinkle — round wings, top-knot, holding a heart.
    static let twinkle: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(circle(310, 430, 140))                                    // wing
        b.add(circle(690, 430, 140))                                    // wing
        b.add(circle(330, 640, 100))                                    // wing
        b.add(circle(670, 640, 100))                                    // wing
        b.add(gown(topY: 470, hemY: 770, topHalf: 70, hemHalf: 180))     // dress
        b.add(leaf(360, 560, 36, 130, angle: 0.35))                     // arm
        b.add(leaf(640, 560, 36, 130, angle: -0.35))                    // arm
        b.add(rect(470, 430, 60, 55))                                    // neck
        b.add(rect(460, 780, 36, 120, corner: 16))                       // leg
        b.add(rect(504, 780, 36, 120, corner: 16))                       // leg
        b.add(circle(500, 330, 112))                                     // head
        b.add(circle(500, 200, 48))                                      // top-knot
        b.add(blob([(392, 300), (400, 215), (500, 195), (600, 215),      // hair
                    (608, 310), (560, 262), (500, 254), (440, 262)]))
        b.add(circle(460, 330, 16))                                      // eye
        b.add(circle(540, 330, 16))                                      // eye
        b.add(heart(500, 660, 70))                                       // heart
        return ColoringPage(id: "twinkle", title: "Twinkle", emoji: "🧚",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions, decorations: face(),
                            cardTint: Color(red: 1.0, green: 0.86, blue: 0.94))
    }()
}

/// A filled heart centred horizontally at cx with its top lobes near cy.
func heart(_ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: cx, y: cy + s))
    p.addCurve(to: CGPoint(x: cx - s, y: cy - s * 0.3),
               control1: CGPoint(x: cx - s * 0.6, y: cy + s * 0.5),
               control2: CGPoint(x: cx - s, y: cy + s * 0.1))
    p.addArc(center: CGPoint(x: cx - s * 0.5, y: cy - s * 0.4), radius: s * 0.5,
             startAngle: .degrees(160), endAngle: .degrees(-20), clockwise: false)
    p.addArc(center: CGPoint(x: cx + s * 0.5, y: cy - s * 0.4), radius: s * 0.5,
             startAngle: .degrees(200), endAngle: .degrees(20), clockwise: false)
    p.addCurve(to: CGPoint(x: cx, y: cy + s),
               control1: CGPoint(x: cx + s, y: cy + s * 0.1),
               control2: CGPoint(x: cx + s * 0.6, y: cy + s * 0.5))
    p.closeSubpath()
    return p
}
