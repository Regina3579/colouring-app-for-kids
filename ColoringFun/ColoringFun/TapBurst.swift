import SwiftUI
import AudioToolbox
#if canImport(UIKit)
import UIKit
#endif

/// Haptic + sound played when a category or picture is tapped.
enum TapFX {
    static func play() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()   // gentle vibration
        AudioServicesPlaySystemSound(1003)   // soft chime — replace with a custom sound later
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

    init(duration: Double = 0.75) {
        self.duration = duration
        // Soft, mostly-white palette with gentle pops of pastel colour.
        let palette: [Color] = [.white, Candy.pink, .white, Candy.blue, Candy.yellow,
                                .white, Candy.purple, Candy.teal, .white, Candy.orange]
        var rng = SeededGenerator(seed: 0xBADC0FFEE0DDF00D)
        stars = (0..<60).map { i in
            BurstStar(angle: rng.unit() * .pi * 2,
                      distance: 0.12 + CGFloat(rng.unit()) * 0.58,
                      size: 0.5 + CGFloat(rng.unit()) * 1.0,
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
                    let scale = s.size * CGFloat(1 - t * 0.2)
                    // Soft fade-in then out, with a gentle glow around each star.
                    let level = max(0.0, sin(.pi * t)) * 0.9
                    drawTwinkle(&ctx, at: CGPoint(x: x, y: y), color: s.color,
                                size: 4.6 * scale, level: level)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
