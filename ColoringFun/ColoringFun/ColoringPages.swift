import SwiftUI

// MARK: - Animals category

enum AnimalPages {
    static let all: [ColoringPage] = [dino, cat, dog, rabbit, bear, lion, elephant, fish, butterfly]

    static let dino: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))                                   // sky
        b.add(circle(820, 160, 78))                                     // sun
        b.add(poly([(0, 720), (250, 440), (520, 720)]))                 // mountain
        b.add(poly([(430, 720), (720, 380), (1000, 720)]))             // mountain
        b.add(rect(0, 690, 1000, 310))                                  // grass
        b.add(blob([(250, 470), (330, 350), (440, 380), (470, 480),    // body
                    (520, 560), (760, 470), (880, 540), (840, 700),
                    (650, 720), (470, 760), (300, 740), (240, 600)]))
        b.add(ellipse(560, 660, 140, 88))                               // belly
        b.add(circle(440, 600, 40))                                     // spot
        b.add(circle(630, 580, 36))                                     // spot
        b.add(circle(740, 630, 32))                                     // spot
        b.add(poly([(420, 380), (470, 300), (520, 385)]))              // spike
        b.add(poly([(545, 405), (605, 320), (665, 415)]))             // spike
        b.add(poly([(685, 450), (745, 375), (795, 475)]))             // spike
        b.add(circle(340, 430, 17))                                     // eye

        var deco = Path()
        deco.move(to: CGPoint(x: 280, y: 470))
        deco.addQuadCurve(to: CGPoint(x: 340, y: 500), control: CGPoint(x: 310, y: 512))
        for a in stride(from: 0.0, to: .pi * 2, by: .pi / 6) {
            let ca = CGFloat(a)
            deco.move(to: CGPoint(x: 820 + cos(ca) * 92, y: 160 + sin(ca) * 92))
            deco.addLine(to: CGPoint(x: 820 + cos(ca) * 120, y: 160 + sin(ca) * 120))
        }
        return ColoringPage(id: "dino", title: "Dino", emoji: "🦕",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions, decorations: deco,
                            cardTint: Color(red: 1.0, green: 0.85, blue: 0.70))
    }()

    static let cat: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))                                   // background
        b.add(poly([(330, 360), (300, 150), (470, 300)]))             // ear
        b.add(poly([(670, 360), (700, 150), (530, 300)]))             // ear
        b.add(poly([(360, 350), (345, 235), (450, 320)]))             // inner ear
        b.add(poly([(640, 350), (655, 235), (550, 320)]))             // inner ear
        b.add(blob([(330, 720), (360, 600), (500, 575), (640, 600),    // body
                    (690, 760), (640, 900), (500, 930), (360, 900)]))
        b.add(circle(500, 470, 195))                                    // head
        b.add(circle(432, 455, 28))                                     // eye
        b.add(circle(568, 455, 28))                                     // eye
        b.add(poly([(472, 520), (528, 520), (500, 558)]))             // nose
        b.add(leaf(745, 740, 130, 44, angle: -0.7))                    // tail

        var deco = Path()
        deco.move(to: CGPoint(x: 500, y: 558)); deco.addLine(to: CGPoint(x: 500, y: 590))
        deco.addQuadCurve(to: CGPoint(x: 452, y: 614), control: CGPoint(x: 472, y: 616))
        deco.move(to: CGPoint(x: 500, y: 590))
        deco.addQuadCurve(to: CGPoint(x: 548, y: 614), control: CGPoint(x: 528, y: 616))
        for dy in [-18.0, 12.0, 42.0] {
            deco.move(to: CGPoint(x: 470, y: 540 + dy)); deco.addLine(to: CGPoint(x: 300, y: 522 + dy))
            deco.move(to: CGPoint(x: 530, y: 540 + dy)); deco.addLine(to: CGPoint(x: 700, y: 522 + dy))
        }
        return ColoringPage(id: "cat", title: "Kitty", emoji: "🐱",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions, decorations: deco,
                            cardTint: Color(red: 1.0, green: 0.80, blue: 0.88))
    }()

    static let dog: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(rect(0, 800, 1000, 200))                                  // floor
        b.add(leaf(370, 470, 70, 150, angle: 0.25))                     // ear
        b.add(leaf(630, 470, 70, 150, angle: -0.25))                    // ear
        b.add(blob([(330, 760), (360, 620), (500, 595), (640, 620),     // body
                    (690, 800), (650, 900), (500, 925), (350, 900)]))
        b.add(circle(500, 470, 185))                                    // head
        b.add(ellipse(500, 540, 95, 78))                                // snout
        b.add(circle(440, 440, 26))                                     // eye
        b.add(circle(560, 440, 26))                                     // eye
        b.add(ellipse(500, 510, 36, 26))                                // nose
        b.add(ellipse(420, 905, 70, 45))                                // paw
        b.add(ellipse(580, 905, 70, 45))                                // paw

        var deco = Path()
        deco.move(to: CGPoint(x: 500, y: 536)); deco.addLine(to: CGPoint(x: 500, y: 575))
        deco.addQuadCurve(to: CGPoint(x: 455, y: 600), control: CGPoint(x: 475, y: 602))
        deco.move(to: CGPoint(x: 500, y: 575))
        deco.addQuadCurve(to: CGPoint(x: 545, y: 600), control: CGPoint(x: 525, y: 602))
        return ColoringPage(id: "dog", title: "Puppy", emoji: "🐶",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions, decorations: deco,
                            cardTint: Color(red: 1.0, green: 0.88, blue: 0.74))
    }()

    static let rabbit: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(rect(0, 820, 1000, 180))                                  // grass
        b.add(leaf(430, 250, 52, 175, angle: -0.12))                    // ear
        b.add(leaf(570, 250, 52, 175, angle: 0.12))                     // ear
        b.add(leaf(430, 270, 26, 130, angle: -0.12))                    // inner ear
        b.add(leaf(570, 270, 26, 130, angle: 0.12))                     // inner ear
        b.add(blob([(360, 800), (380, 650), (500, 615), (620, 650),     // body
                    (660, 820), (610, 910), (500, 930), (390, 910)]))
        b.add(circle(500, 500, 170))                                    // head
        b.add(circle(445, 480, 24))                                     // eye
        b.add(circle(555, 480, 24))                                     // eye
        b.add(poly([(478, 540), (522, 540), (500, 568)]))             // nose
        b.add(circle(360, 880, 48))                                     // foot
        b.add(circle(640, 880, 48))                                     // foot
        b.add(circle(700, 800, 40))                                     // tail
        return ColoringPage(id: "rabbit", title: "Bunny", emoji: "🐰",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions,
                            cardTint: Color(red: 0.92, green: 0.88, blue: 1.0))
    }()

    static let bear: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(circle(360, 330, 90))                                     // ear
        b.add(circle(640, 330, 90))                                     // ear
        b.add(circle(360, 330, 48))                                     // inner ear
        b.add(circle(640, 330, 48))                                     // inner ear
        b.add(blob([(340, 780), (370, 640), (500, 615), (630, 640),     // body
                    (665, 800), (620, 905), (500, 930), (380, 905)]))
        b.add(circle(500, 470, 190))                                    // head
        b.add(ellipse(500, 535, 92, 72))                                // snout
        b.add(circle(440, 440, 24))                                     // eye
        b.add(circle(560, 440, 24))                                     // eye
        b.add(ellipse(500, 505, 34, 24))                                // nose
        b.add(circle(400, 880, 52))                                     // paw
        b.add(circle(600, 880, 52))                                     // paw
        return ColoringPage(id: "bear", title: "Teddy", emoji: "🐻",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions,
                            cardTint: Color(red: 0.93, green: 0.84, blue: 0.72))
    }()

    static let lion: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        // fluffy mane as a bumpy blob ring
        var mane: [(CGFloat, CGFloat)] = []
        let bumps = 14
        for k in 0..<bumps {
            let a = CGFloat(k) / CGFloat(bumps) * .pi * 2
            let r: CGFloat = k % 2 == 0 ? 250 : 200
            mane.append((500 + cos(a) * r, 470 + sin(a) * r))
        }
        b.add(blob(mane))                                               // mane
        b.add(blob([(370, 800), (400, 690), (500, 670), (600, 690),     // body
                    (635, 820), (590, 910), (500, 930), (410, 910)]))
        b.add(circle(500, 470, 168))                                    // face
        b.add(circle(420, 445, 22))                                     // eye
        b.add(circle(580, 445, 22))                                     // eye
        b.add(poly([(476, 505), (524, 505), (500, 535)]))             // nose
        b.add(circle(395, 905, 46))                                     // paw
        b.add(circle(605, 905, 46))                                     // paw

        var deco = Path()
        deco.move(to: CGPoint(x: 500, y: 535)); deco.addLine(to: CGPoint(x: 500, y: 565))
        deco.addQuadCurve(to: CGPoint(x: 458, y: 588), control: CGPoint(x: 478, y: 590))
        deco.move(to: CGPoint(x: 500, y: 565))
        deco.addQuadCurve(to: CGPoint(x: 542, y: 588), control: CGPoint(x: 522, y: 590))
        return ColoringPage(id: "lion", title: "Lion", emoji: "🦁",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions, decorations: deco,
                            cardTint: Color(red: 1.0, green: 0.86, blue: 0.62))
    }()

    static let elephant: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(rect(0, 820, 1000, 180))                                  // ground
        b.add(circle(330, 480, 150))                                    // ear
        b.add(circle(670, 480, 150))                                    // ear
        b.add(blob([(350, 800), (380, 560), (500, 520), (620, 560),     // head/body
                    (650, 800), (600, 880), (400, 880)]))
        b.add(blob([(470, 560), (530, 560), (560, 720), (540, 820),     // trunk
                    (470, 840), (455, 740)]))
        b.add(circle(440, 470, 22))                                     // eye
        b.add(circle(560, 470, 22))                                     // eye
        b.add(rect(400, 850, 60, 90, corner: 22))                       // leg
        b.add(rect(540, 850, 60, 90, corner: 22))                       // leg
        return ColoringPage(id: "elephant", title: "Elephant", emoji: "🐘",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions,
                            cardTint: Color(red: 0.84, green: 0.88, blue: 0.92))
    }()

    static let fish: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))                                   // water
        b.add(poly([(720, 500), (940, 350), (940, 650)]))             // tail
        b.add(poly([(420, 380), (560, 250), (600, 400)]))             // top fin
        b.add(poly([(420, 620), (560, 750), (600, 600)]))             // bottom fin
        b.add(ellipse(450, 500, 290, 205))                              // body
        b.add(circle(305, 455, 34))                                     // eye
        b.add(circle(540, 560, 28))                                     // spot
        b.add(circle(470, 470, 24))                                     // spot
        b.add(circle(560, 440, 22))                                     // spot
        b.add(circle(820, 200, 32))                                     // bubble
        b.add(circle(890, 300, 22))                                     // bubble
        b.add(circle(850, 380, 15))                                     // bubble

        var deco = Path()
        deco.move(to: CGPoint(x: 225, y: 535))
        deco.addQuadCurve(to: CGPoint(x: 320, y: 555), control: CGPoint(x: 272, y: 598))
        return ColoringPage(id: "fish", title: "Fish", emoji: "🐠",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions, decorations: deco,
                            cardTint: Color(red: 0.75, green: 0.90, blue: 0.95))
    }()

    static let butterfly: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(ellipse(350, 360, 150, 168))                              // wing
        b.add(ellipse(650, 360, 150, 168))                              // wing
        b.add(ellipse(370, 640, 128, 138))                              // wing
        b.add(ellipse(630, 640, 128, 138))                              // wing
        b.add(circle(350, 360, 48))                                     // dot
        b.add(circle(650, 360, 48))                                     // dot
        b.add(circle(370, 640, 40))                                     // dot
        b.add(circle(630, 640, 40))                                     // dot
        b.add(rect(478, 300, 44, 440, corner: 22))                      // body
        b.add(circle(500, 280, 35))                                     // head

        var deco = Path()
        deco.move(to: CGPoint(x: 485, y: 260))
        deco.addQuadCurve(to: CGPoint(x: 420, y: 175), control: CGPoint(x: 430, y: 235))
        deco.move(to: CGPoint(x: 515, y: 260))
        deco.addQuadCurve(to: CGPoint(x: 580, y: 175), control: CGPoint(x: 570, y: 235))
        return ColoringPage(id: "butterfly", title: "Flutter", emoji: "🦋",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions, decorations: deco,
                            cardTint: Color(red: 0.86, green: 0.80, blue: 0.95))
    }()
}
