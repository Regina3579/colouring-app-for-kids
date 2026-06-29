import SwiftUI
import AudioToolbox
#if canImport(UIKit)
import UIKit
#endif

/// Haptic + sound played when a category or picture is tapped.
enum TapFX {
    static func play() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        AudioServicesPlaySystemSound(1057)   // a light "tink" — replace with a custom sound later
        #endif
    }
}

private struct BurstStar: Identifiable {
    let id = UUID()
    let angle: Double
    let distance: CGFloat   // fraction of the smaller screen dimension
    let size: CGFloat
    let spin: Double
    let color: Color
}

/// A quick celebratory burst of stars spreading out from the centre.
struct StarBurst: View {
    private let duration: Double
    @State private var start = Date()
    private let stars: [BurstStar]

    init(duration: Double = 0.6) {
        self.duration = duration
        let palette: [Color] = [Candy.pink, Candy.blue, Candy.yellow, Candy.purple,
                                Candy.orange, Candy.teal, Candy.green]
        var rng = SeededGenerator(seed: 0xBADC0FFEE0DDF00D)
        stars = (0..<28).map { i in
            BurstStar(angle: rng.unit() * .pi * 2,
                      distance: 0.16 + CGFloat(rng.unit()) * 0.52,
                      size: 0.6 + CGFloat(rng.unit()) * 1.2,
                      spin: -1 + rng.unit() * 2,
                      color: palette[i % palette.count])
        }
    }

    var body: some View {
        TimelineView(.animation) { tl in
            let raw = tl.date.timeIntervalSince(start) / duration
            let t = min(1.0, max(0.0, raw))
            let ease = 1 - pow(1 - t, 3)
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height * 0.42)
                let unit = min(size.width, size.height)
                for s in stars {
                    let dist = CGFloat(ease) * s.distance * unit
                    let x = center.x + CGFloat(cos(s.angle)) * dist
                    let y = center.y + CGFloat(sin(s.angle)) * dist
                    let scale = s.size * CGFloat(1 - t * 0.25)
                    let alpha = 1 - t
                    let p = CGPoint(x: x, y: y)
                    ctx.drawLayer { l in
                        l.translateBy(x: x, y: y)
                        l.rotate(by: .radians(s.spin * t * 5))
                        l.translateBy(x: -x, y: -y)
                        l.fill(sparkleStarPath(at: p, size: 9 * scale),
                               with: .color(s.color.opacity(alpha)))
                        l.fill(sparkleStarPath(at: p, size: 4 * scale),
                               with: .color(.white.opacity(alpha)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
