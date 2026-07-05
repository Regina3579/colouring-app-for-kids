import SwiftUI

// MARK: - Birds category

enum BirdPages {
    static let all: [ColoringPage] = [owl, chick, duck, penguin, parrot, peacock]

    static let owl: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(rect(120, 760, 760, 70, corner: 30))                      // branch
        b.add(poly([(330, 300), (300, 200), (430, 290)]))             // ear tuft
        b.add(poly([(670, 300), (700, 200), (570, 290)]))             // ear tuft
        b.add(blob([(300, 760), (300, 450), (500, 300), (700, 450),     // body
                    (700, 760), (600, 850), (400, 850)]))
        b.add(circle(415, 460, 95))                                     // eye disc
        b.add(circle(585, 460, 95))                                     // eye disc
        b.add(circle(415, 460, 42))                                     // eye
        b.add(circle(585, 460, 42))                                     // eye
        b.add(poly([(470, 510), (530, 510), (500, 575)]))             // beak
        b.add(blob([(380, 620), (500, 600), (620, 620), (600, 770),     // tummy
                    (500, 800), (400, 770)]))
        b.add(ellipse(460, 880, 38, 24))                                // foot
        b.add(ellipse(540, 880, 38, 24))                                // foot
        return ColoringPage(id: "owl", title: "Owl", emoji: "🦉",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions,
                            cardTint: Color(red: 0.86, green: 0.82, blue: 0.74))
    }()

    static let chick: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(rect(0, 840, 1000, 160))                                  // ground
        b.add(blob([(350, 760), (380, 600), (500, 560), (620, 600),     // body
                    (660, 770), (610, 880), (500, 905), (390, 880)]))
        b.add(circle(500, 420, 165))                                    // head
        b.add(poly([(440, 230), (470, 160), (500, 235)]))             // tuft
        b.add(poly([(500, 235), (530, 160), (560, 235)]))             // tuft
        b.add(circle(450, 405, 24))                                     // eye
        b.add(circle(550, 405, 24))                                     // eye
        b.add(poly([(465, 455), (535, 455), (500, 510)]))             // beak
        b.add(leaf(330, 720, 95, 55, angle: -0.4))                      // wing
        b.add(leaf(670, 720, 95, 55, angle: 0.4))                       // wing
        b.add(poly([(440, 900), (470, 965), (415, 960)]))             // foot
        b.add(poly([(560, 900), (530, 965), (585, 960)]))             // foot
        return ColoringPage(id: "chick", title: "Chick", emoji: "🐥",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions,
                            cardTint: Color(red: 1.0, green: 0.93, blue: 0.66))
    }()

    static let duck: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 620))                                    // sky
        b.add(rect(0, 600, 1000, 400))                                  // pond
        b.add(blob([(300, 720), (330, 560), (520, 520), (700, 560),     // body
                    (760, 700), (700, 800), (450, 820), (310, 780)]))
        b.add(poly([(700, 600), (820, 540), (770, 660)]))             // tail
        b.add(circle(360, 430, 130))                                    // head
        b.add(circle(320, 405, 22))                                     // eye
        b.add(blob([(200, 430), (270, 405), (300, 440), (270, 480), (200, 470)]))  // bill
        b.add(leaf(520, 700, 110, 65, angle: 0.1))                      // wing
        return ColoringPage(id: "duck", title: "Duck", emoji: "🦆",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions,
                            cardTint: Color(red: 0.80, green: 0.92, blue: 0.98))
    }()

    static let penguin: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))                                   // sky
        b.add(rect(0, 860, 1000, 140))                                  // snow
        b.add(blob([(330, 800), (340, 420), (500, 250), (660, 420),     // body
                    (670, 800), (590, 880), (410, 880)]))
        b.add(blob([(400, 760), (410, 470), (500, 380), (590, 470),     // tummy
                    (600, 760), (500, 820)]))
        b.add(circle(450, 400, 22))                                     // eye
        b.add(circle(550, 400, 22))                                     // eye
        b.add(poly([(470, 440), (530, 440), (500, 490)]))             // beak
        b.add(leaf(310, 600, 55, 150, angle: 0.2))                      // flipper
        b.add(leaf(690, 600, 55, 150, angle: -0.2))                     // flipper
        b.add(poly([(420, 880), (490, 880), (440, 940)]))             // foot
        b.add(poly([(580, 880), (510, 880), (560, 940)]))             // foot
        return ColoringPage(id: "penguin", title: "Penguin", emoji: "🐧",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions,
                            cardTint: Color(red: 0.82, green: 0.90, blue: 0.96))
    }()

    static let parrot: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        b.add(rect(620, 200, 60, 720, corner: 20))                      // perch
        b.add(blob([(380, 760), (360, 450), (500, 300), (640, 430),     // body
                    (640, 720), (560, 820), (430, 810)]))
        b.add(poly([(560, 700), (760, 850), (600, 860)]))             // tail
        b.add(circle(470, 360, 120))                                    // head
        b.add(poly([(440, 230), (500, 170), (520, 250)]))             // crest
        b.add(circle(450, 350, 22))                                     // eye
        b.add(blob([(360, 360), (440, 330), (460, 390), (400, 430), (350, 405)]))  // beak
        b.add(leaf(520, 600, 95, 60, angle: 0.3))                       // wing
        return ColoringPage(id: "parrot", title: "Parrot", emoji: "🦜",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions,
                            cardTint: Color(red: 0.78, green: 0.94, blue: 0.80))
    }()

    static let peacock: ColoringPage = {
        let b = RegionBuilder()
        b.add(rect(0, 0, 1000, 1000))
        // big fan of feathers
        b.add(circle(500, 540, 360))                                    // fan
        for k in 0..<8 {
            let a = CGFloat(k) / 8 * .pi - .pi / 2 - 0.2
            let x = 500 + cos(a) * 300
            let y = 540 + sin(a) * 300
            b.add(circle(x, y, 60))                                     // feather eye outer
        }
        b.add(blob([(440, 820), (450, 560), (500, 470), (550, 560),     // body
                    (560, 820), (500, 880)]))
        b.add(circle(500, 430, 70))                                     // head
        b.add(circle(478, 420, 16))                                     // eye
        b.add(poly([(500, 445), (470, 480), (530, 480)]))             // beak
        return ColoringPage(id: "peacock", title: "Peacock", emoji: "🦚",
                            canvas: CGSize(width: 1000, height: 1000),
                            regions: b.regions,
                            cardTint: Color(red: 0.74, green: 0.90, blue: 0.92))
    }()
}
