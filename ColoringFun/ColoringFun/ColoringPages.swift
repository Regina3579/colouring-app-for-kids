import SwiftUI

// MARK: - Small path building helpers (all in a 1000 x 1000 design space)

private func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
}

private func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
}

private func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, corner: CGFloat = 0) -> Path {
    Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: corner)
}

private func poly(_ pts: [(CGFloat, CGFloat)]) -> Path {
    var p = Path()
    guard let first = pts.first else { return p }
    p.move(to: CGPoint(x: first.0, y: first.1))
    for pt in pts.dropFirst() { p.addLine(to: CGPoint(x: pt.0, y: pt.1)) }
    p.closeSubpath()
    return p
}

/// A rounded petal/leaf ellipse rotated around its own centre.
private func leaf(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, angle: CGFloat) -> Path {
    let base = ellipse(cx, cy, rx, ry)
    let t = CGAffineTransform(translationX: cx, y: cy)
        .rotated(by: angle)
        .translatedBy(x: -cx, y: -cy)
    return base.applying(t)
}

// MARK: - The picture library

enum Pages {
    static let all: [ColoringPage] = [dino, kitty, fish, butterfly, flower, house]

    // 1. Dinosaur in a meadow ----------------------------------------------
    static let dino: ColoringPage = {
        var r: [Region] = []
        var i = 0
        func add(_ p: Path) { r.append(Region(id: i, path: p)); i += 1 }

        add(rect(0, 0, 1000, 1000))                                   // sky
        add(circle(810, 170, 80))                                     // sun
        add(poly([(0, 700), (260, 430), (520, 700)]))                 // mountain left
        add(poly([(420, 700), (700, 380), (1000, 700)]))              // mountain right
        add(rect(0, 660, 1000, 340))                                  // grass

        // Dinosaur body silhouette (head, neck, body, tail) as one path.
        var body = Path()
        body.move(to: CGPoint(x: 250, y: 470))
        body.addCurve(to: CGPoint(x: 360, y: 360),
                      control1: CGPoint(x: 250, y: 400), control2: CGPoint(x: 290, y: 360))
        body.addCurve(to: CGPoint(x: 470, y: 470),
                      control1: CGPoint(x: 430, y: 360), control2: CGPoint(x: 470, y: 410))
        body.addCurve(to: CGPoint(x: 520, y: 560),
                      control1: CGPoint(x: 470, y: 520), control2: CGPoint(x: 490, y: 540))
        body.addCurve(to: CGPoint(x: 880, y: 560),
                      control1: CGPoint(x: 640, y: 660), control2: CGPoint(x: 770, y: 470))
        body.addCurve(to: CGPoint(x: 720, y: 760),
                      control1: CGPoint(x: 950, y: 640), control2: CGPoint(x: 820, y: 760))
        body.addLine(to: CGPoint(x: 470, y: 760))
        body.addCurve(to: CGPoint(x: 250, y: 470),
                      control1: CGPoint(x: 300, y: 760), control2: CGPoint(x: 250, y: 620))
        body.closeSubpath()
        add(body)

        add(ellipse(560, 660, 140, 90))                               // belly
        add(circle(430, 600, 42))                                     // spot 1
        add(circle(620, 560, 38))                                     // spot 2
        add(circle(740, 620, 34))                                     // spot 3
        add(poly([(420, 380), (470, 300), (520, 380)]))               // back spike 1
        add(poly([(540, 400), (600, 320), (660, 410)]))               // back spike 2
        add(poly([(680, 440), (740, 370), (790, 470)]))               // back spike 3
        add(circle(330, 430, 18))                                     // eye

        var deco = Path()
        // little smile on the dino
        deco.move(to: CGPoint(x: 270, y: 470))
        deco.addQuadCurve(to: CGPoint(x: 330, y: 500), control: CGPoint(x: 300, y: 510))
        // sun rays
        for a in stride(from: 0.0, to: .pi * 2, by: .pi / 6) {
            let ca = CGFloat(a)
            deco.move(to: CGPoint(x: 810 + cos(ca) * 95, y: 170 + sin(ca) * 95))
            deco.addLine(to: CGPoint(x: 810 + cos(ca) * 125, y: 170 + sin(ca) * 125))
        }

        return ColoringPage(id: "dino", title: "Dino", emoji: "🦕",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: r, decorations: deco,
                            cardTint: Color(red: 1.0, green: 0.85, blue: 0.70))
    }()

    // 2. Kitty cat ----------------------------------------------------------
    static let kitty: ColoringPage = {
        var r: [Region] = []
        var i = 0
        func add(_ p: Path) { r.append(Region(id: i, path: p)); i += 1 }

        add(rect(0, 0, 1000, 1000))                                   // background
        add(poly([(330, 360), (300, 150), (470, 300)]))               // ear left
        add(poly([(670, 360), (700, 150), (530, 300)]))               // ear right
        add(poly([(360, 350), (345, 230), (455, 320)]))               // inner ear left
        add(poly([(640, 350), (655, 230), (545, 320)]))               // inner ear right
        add(ellipse(500, 760, 210, 170))                              // body
        add(circle(500, 470, 200))                                    // head
        add(circle(430, 450, 30))                                     // eye left
        add(circle(570, 450, 30))                                     // eye right
        add(poly([(470, 520), (530, 520), (500, 560)]))               // nose
        add(leaf(740, 720, 130, 45, angle: -0.7))                     // tail

        var deco = Path()
        // mouth
        deco.move(to: CGPoint(x: 500, y: 560))
        deco.addLine(to: CGPoint(x: 500, y: 590))
        deco.addQuadCurve(to: CGPoint(x: 450, y: 615), control: CGPoint(x: 470, y: 615))
        deco.move(to: CGPoint(x: 500, y: 590))
        deco.addQuadCurve(to: CGPoint(x: 550, y: 615), control: CGPoint(x: 530, y: 615))
        // whiskers
        for dy in [-20.0, 10.0, 40.0] {
            deco.move(to: CGPoint(x: 470, y: 540 + dy)); deco.addLine(to: CGPoint(x: 300, y: 520 + dy))
            deco.move(to: CGPoint(x: 530, y: 540 + dy)); deco.addLine(to: CGPoint(x: 700, y: 520 + dy))
        }

        return ColoringPage(id: "kitty", title: "Kitty", emoji: "🐱",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: r, decorations: deco,
                            cardTint: Color(red: 1.0, green: 0.80, blue: 0.88))
    }()

    // 3. Happy fish ---------------------------------------------------------
    static let fish: ColoringPage = {
        var r: [Region] = []
        var i = 0
        func add(_ p: Path) { r.append(Region(id: i, path: p)); i += 1 }

        add(rect(0, 0, 1000, 1000))                                   // water
        add(poly([(720, 500), (940, 350), (940, 650)]))               // tail
        add(poly([(420, 380), (560, 250), (600, 400)]))               // top fin
        add(poly([(420, 620), (560, 750), (600, 600)]))               // bottom fin
        add(ellipse(450, 500, 290, 210))                              // body
        add(circle(300, 450, 36))                                     // eye
        add(circle(540, 560, 30))                                     // scale spot 1
        add(circle(470, 470, 26))                                     // scale spot 2
        add(circle(560, 440, 24))                                     // scale spot 3
        add(circle(820, 200, 34))                                     // bubble 1
        add(circle(890, 300, 24))                                     // bubble 2
        add(circle(850, 380, 16))                                     // bubble 3

        var deco = Path()
        // smile
        deco.move(to: CGPoint(x: 220, y: 540))
        deco.addQuadCurve(to: CGPoint(x: 320, y: 560), control: CGPoint(x: 270, y: 600))

        return ColoringPage(id: "fish", title: "Fish", emoji: "🐠",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: r, decorations: deco,
                            cardTint: Color(red: 0.75, green: 0.90, blue: 0.95))
    }()

    // 4. Butterfly ----------------------------------------------------------
    static let butterfly: ColoringPage = {
        var r: [Region] = []
        var i = 0
        func add(_ p: Path) { r.append(Region(id: i, path: p)); i += 1 }

        add(rect(0, 0, 1000, 1000))                                   // background
        add(ellipse(350, 360, 150, 170))                              // upper wing left
        add(ellipse(650, 360, 150, 170))                              // upper wing right
        add(ellipse(370, 640, 130, 140))                              // lower wing left
        add(ellipse(630, 640, 130, 140))                              // lower wing right
        add(circle(350, 360, 50))                                     // dot upper left
        add(circle(650, 360, 50))                                     // dot upper right
        add(circle(370, 640, 42))                                     // dot lower left
        add(circle(630, 640, 42))                                     // dot lower right
        add(rect(478, 300, 44, 440, corner: 22))                      // body
        add(circle(500, 280, 36))                                     // head

        var deco = Path()
        // antennae
        deco.move(to: CGPoint(x: 485, y: 260))
        deco.addQuadCurve(to: CGPoint(x: 420, y: 175), control: CGPoint(x: 430, y: 235))
        deco.move(to: CGPoint(x: 515, y: 260))
        deco.addQuadCurve(to: CGPoint(x: 580, y: 175), control: CGPoint(x: 570, y: 235))

        return ColoringPage(id: "butterfly", title: "Flutter", emoji: "🦋",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: r, decorations: deco,
                            cardTint: Color(red: 0.86, green: 0.80, blue: 0.95))
    }()

    // 5. Flower in the garden ----------------------------------------------
    static let flower: ColoringPage = {
        var r: [Region] = []
        var i = 0
        func add(_ p: Path) { r.append(Region(id: i, path: p)); i += 1 }

        add(rect(0, 0, 1000, 640))                                    // sky
        add(rect(0, 600, 1000, 400))                                  // grass
        add(rect(480, 380, 40, 360, corner: 20))                      // stem
        add(leaf(370, 560, 110, 50, angle: -0.5))                     // leaf left
        add(leaf(630, 560, 110, 50, angle: 0.5))                      // leaf right
        // six petals around the centre
        let cx: CGFloat = 500, cy: CGFloat = 300, pr: CGFloat = 130
        for k in 0..<6 {
            let a = CGFloat(k) * .pi / 3
            add(leaf(cx + cos(a) * 150, cy + sin(a) * 150, 95, 55, angle: a))
        }
        add(circle(cx, cy, 90))                                       // flower centre

        return ColoringPage(id: "flower", title: "Flower", emoji: "🌸",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: r,
                            cardTint: Color(red: 1.0, green: 0.86, blue: 0.92))
    }()

    // 6. Cozy house --------------------------------------------------------
    static let house: ColoringPage = {
        var r: [Region] = []
        var i = 0
        func add(_ p: Path) { r.append(Region(id: i, path: p)); i += 1 }

        add(rect(0, 0, 1000, 1000))                                   // sky
        add(circle(180, 180, 90))                                     // sun
        add(rect(0, 720, 1000, 280))                                  // grass
        add(rect(280, 460, 440, 320))                                 // wall
        add(poly([(240, 460), (500, 250), (760, 460)]))               // roof
        add(rect(360, 230, 70, 130))                                  // chimney
        add(rect(440, 600, 120, 180, corner: 10))                     // door
        add(rect(330, 520, 110, 100, corner: 8))                      // window left
        add(rect(560, 520, 110, 100, corner: 8))                      // window right

        var deco = Path()
        // window crosses
        deco.move(to: CGPoint(x: 385, y: 520)); deco.addLine(to: CGPoint(x: 385, y: 620))
        deco.move(to: CGPoint(x: 330, y: 570)); deco.addLine(to: CGPoint(x: 440, y: 570))
        deco.move(to: CGPoint(x: 615, y: 520)); deco.addLine(to: CGPoint(x: 615, y: 620))
        deco.move(to: CGPoint(x: 560, y: 570)); deco.addLine(to: CGPoint(x: 670, y: 570))
        // door knob
        deco.addEllipse(in: CGRect(x: 525, y: 690, width: 18, height: 18))
        // sun rays
        for a in stride(from: 0.0, to: .pi * 2, by: .pi / 6) {
            let ca = CGFloat(a)
            deco.move(to: CGPoint(x: 180 + cos(ca) * 105, y: 180 + sin(ca) * 105))
            deco.addLine(to: CGPoint(x: 180 + cos(ca) * 140, y: 180 + sin(ca) * 140))
        }

        return ColoringPage(id: "house", title: "House", emoji: "🏠",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: r, decorations: deco,
                            cardTint: Color(red: 0.80, green: 0.92, blue: 0.85))
    }()
}
