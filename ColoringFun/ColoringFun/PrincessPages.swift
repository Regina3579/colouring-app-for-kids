import SwiftUI

// MARK: - Princess category (original characters, not based on any brand)

enum PrincessPages {
    static let all: [ColoringPage] = [rosa, lily, aurelia, marina]

    /// Smile + rosy cheeks shared by the princesses.
    private static func face(cheekY: CGFloat = 360) -> Path {
        var d = Path()
        d.move(to: CGPoint(x: 470, y: 380))
        d.addQuadCurve(to: CGPoint(x: 530, y: 380), control: CGPoint(x: 500, y: 410))
        d.addEllipse(in: CGRect(x: 430, y: cheekY, width: 34, height: 22))
        d.addEllipse(in: CGRect(x: 536, y: cheekY, width: 34, height: 22))
        return d
    }

    // Princess Rosa — long hair, zig-zag crown, wide gown.
    static let rosa: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(blob([(330, 330), (360, 175), (500, 115), (640, 175),     // hair back
                    (675, 330), (705, 580), (640, 720), (560, 650),
                    (500, 615), (440, 650), (360, 720), (295, 580)]))
        b.add(gown(topY: 470, hemY: 900, topHalf: 75, hemHalf: 245))     // gown
        b.add(leaf(360, 590, 42, 150, angle: 0.30))                      // arm
        b.add(leaf(640, 590, 42, 150, angle: -0.30))                     // arm
        b.add(rect(470, 430, 60, 60))                                    // neck
        b.add(circle(500, 330, 118))                                     // head
        b.add(blob([(388, 300), (398, 205), (500, 180), (602, 205),      // bangs
                    (612, 300), (560, 258), (500, 248), (440, 258)]))
        b.add(poly([(405, 215), (430, 150), (462, 205), (500, 135),      // crown
                    (538, 205), (570, 150), (595, 215), (595, 240), (405, 240)]))
        b.add(circle(500, 175, 15))                                      // jewel
        b.add(circle(440, 205, 11))                                      // jewel
        b.add(circle(560, 205, 11))                                      // jewel
        b.add(circle(460, 330, 17))                                      // eye
        b.add(circle(540, 330, 17))                                      // eye
        b.add(ellipse(500, 560, 120, 40))                               // collar
        return ColoringPage(id: "rosa", title: "Rosa", emoji: "👸",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions, decorations: face(),
                            cardTint: Color(red: 1.0, green: 0.82, blue: 0.90))
    }()

    // Princess Lily — twin buns, small tiara, layered gown.
    static let lily: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(circle(360, 250, 78))                                     // bun
        b.add(circle(640, 250, 78))                                     // bun
        b.add(blob([(360, 320), (380, 200), (500, 165), (620, 200),     // hair
                    (640, 320), (620, 430), (500, 400), (380, 430)]))
        b.add(gown(topY: 470, hemY: 890, topHalf: 70, hemHalf: 210))     // gown
        b.add(gown(topY: 640, hemY: 900, topHalf: 150, hemHalf: 250))    // gown skirt layer
        b.add(leaf(355, 580, 40, 140, angle: 0.30))                      // arm
        b.add(leaf(645, 580, 40, 140, angle: -0.30))                     // arm
        b.add(rect(470, 430, 60, 55))                                    // neck
        b.add(circle(500, 330, 115))                                     // head
        b.add(poly([(430, 230), (460, 180), (500, 220), (540, 180),      // tiara
                    (570, 230), (570, 250), (430, 250)]))
        b.add(circle(500, 205, 13))                                      // jewel
        b.add(circle(460, 330, 17))                                      // eye
        b.add(circle(540, 330, 17))                                      // eye
        return ColoringPage(id: "lily", title: "Lily", emoji: "👸",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions, decorations: face(),
                            cardTint: Color(red: 0.86, green: 0.84, blue: 1.0))
    }()

    // Princess Aurelia — side ponytail, star crown, starry gown.
    static let aurelia: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(blob([(360, 320), (380, 200), (500, 165), (620, 200),     // hair
                    (640, 320), (610, 420), (500, 390), (390, 420)]))
        b.add(blob([(620, 300), (760, 360), (800, 540), (740, 720),      // side ponytail
                    (660, 700), (700, 540), (640, 400)]))
        b.add(gown(topY: 470, hemY: 895, topHalf: 72, hemHalf: 235))     // gown
        b.add(leaf(360, 590, 42, 145, angle: 0.30))                      // arm
        b.add(leaf(640, 590, 42, 145, angle: -0.30))                     // arm
        b.add(rect(470, 430, 60, 58))                                    // neck
        b.add(circle(500, 330, 116))                                     // head
        b.add(star5(500, 200, 70))                                       // star crown
        b.add(circle(460, 330, 17))                                      // eye
        b.add(circle(540, 330, 17))                                      // eye
        b.add(star5(440, 700, 34))                                       // gown star
        b.add(star5(560, 760, 30))                                       // gown star
        b.add(star5(500, 840, 26))                                       // gown star
        return ColoringPage(id: "aurelia", title: "Aurelia", emoji: "👸",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions, decorations: face(),
                            cardTint: Color(red: 0.80, green: 0.88, blue: 1.0))
    }()

    // Princess Marina — wavy hair, sea-shell crown, flowing gown.
    static let marina: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(blob([(320, 340), (350, 180), (500, 110), (650, 180),     // wavy hair
                    (680, 340), (720, 600), (650, 760), (590, 660),
                    (560, 720), (500, 640), (440, 720), (410, 660),
                    (350, 760), (280, 600)]))
        b.add(gown(topY: 470, hemY: 900, topHalf: 74, hemHalf: 250))     // gown
        b.add(leaf(360, 590, 42, 150, angle: 0.30))                      // arm
        b.add(leaf(640, 590, 42, 150, angle: -0.30))                     // arm
        b.add(rect(470, 430, 60, 60))                                    // neck
        b.add(circle(500, 330, 118))                                     // head
        b.add(blob([(400, 300), (410, 210), (500, 185), (590, 210),      // bangs
                    (600, 300), (550, 260), (500, 252), (450, 260)]))
        b.add(blob([(430, 210), (460, 150), (500, 195), (540, 150),      // shell crown
                    (570, 210), (560, 235), (440, 235)]))
        b.add(circle(460, 330, 17))                                      // eye
        b.add(circle(540, 330, 17))                                      // eye
        b.add(ellipse(500, 560, 115, 38))                               // collar
        return ColoringPage(id: "marina", title: "Marina", emoji: "👸",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions, decorations: face(),
                            cardTint: Color(red: 0.78, green: 0.92, blue: 0.94))
    }()
}

/// A filled five-point star centred at (cx, cy) with outer radius r.
func star5(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
    var p = Path()
    let inner = r * 0.42
    for k in 0..<10 {
        let rad = k % 2 == 0 ? r : inner
        let a = -CGFloat.pi / 2 + CGFloat(k) * .pi / 5
        let pt = CGPoint(x: cx + cos(a) * rad, y: cy + sin(a) * rad)
        if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
    }
    p.closeSubpath()
    return p
}
