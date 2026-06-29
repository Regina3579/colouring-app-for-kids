import SwiftUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

/// Haptic + a synthesized "twinkle" sound played when a category/picture is tapped.
enum TapFX {
    static func play() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        #endif
        SparkleSound.play()
    }
}

/// Plays a short, bright twinkle (a little ascending sparkle) generated in code.
enum SparkleSound {
    private static var player: AVAudioPlayer?
    private static let data: Data = makeTwinkle()

    static func play() {
        #if canImport(UIKit)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        guard let p = try? AVAudioPlayer(data: data) else { return }
        p.volume = 0.55
        player = p          // keep a strong reference so it isn't deallocated
        p.play()
    }

    private static func makeTwinkle() -> Data {
        let sampleRate = 44100.0
        let total = Int(sampleRate * 0.5)
        var samples = [Double](repeating: 0, count: total)

        // A quick ascending sparkle: bright high notes with fast decay.
        let notes: [Double] = [1318.5, 1760.0, 2093.0, 2637.0, 3136.0]   // E6 A6 C7 E7 G7
        for (i, f) in notes.enumerated() {
            let startIdx = Int(Double(i) * 0.045 * sampleRate)
            let len = Int(0.22 * sampleRate)
            for k in 0..<len {
                let idx = startIdx + k
                if idx >= total { break }
                let t = Double(k) / sampleRate
                let env = exp(-t * 16.0)                       // fast, twinkly decay
                samples[idx] += sin(2 * .pi * f * t) * env * 0.22
                samples[idx] += sin(2 * .pi * f * 2 * t) * env * 0.06   // shimmer harmonic
            }
        }

        // Convert to 16-bit PCM WAV.
        var pcm = [Int16](repeating: 0, count: total)
        for i in 0..<total { pcm[i] = Int16(max(-1, min(1, samples[i])) * 32767) }
        return wav(pcm, sampleRate: Int(sampleRate))
    }

    private static func wav(_ samples: [Int16], sampleRate: Int) -> Data {
        var d = Data()
        let dataSize = samples.count * 2
        func ascii(_ s: String) { d.append(s.data(using: .ascii)!) }
        func u32(_ v: UInt32) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 4)) }
        func u16(_ v: UInt16) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 2)) }
        ascii("RIFF"); u32(UInt32(36 + dataSize)); ascii("WAVE")
        ascii("fmt "); u32(16); u16(1); u16(1); u32(UInt32(sampleRate))
        u32(UInt32(sampleRate * 2)); u16(2); u16(16)
        ascii("data"); u32(UInt32(dataSize))
        for s in samples { var x = s.littleEndian; d.append(Data(bytes: &x, count: 2)) }
        return d
    }
}

private struct BurstStar: Identifiable {
    let id = UUID()
    let angle: Double
    let distance: CGFloat   // fraction of the smaller screen dimension
    let size: CGFloat
    let color: Color
}

/// A soft burst of stars that pops out from `globalOrigin` (the tap point).
struct StarBurst: View {
    let globalOrigin: CGPoint
    private let duration: Double = 0.75
    @State private var start = Date()
    private let stars: [BurstStar]

    init(globalOrigin: CGPoint) {
        self.globalOrigin = globalOrigin
        let palette: [Color] = [.white, Candy.pink, .white, Candy.blue, Candy.yellow,
                                .white, Candy.purple, Candy.teal, .white, Candy.orange]
        var rng = SeededGenerator(seed: 0xBADC0FFEE0DDF00D)
        stars = (0..<60).map { i in
            BurstStar(angle: rng.unit() * .pi * 2,
                      distance: 0.10 + CGFloat(rng.unit()) * 0.5,
                      size: 0.5 + CGFloat(rng.unit()) * 1.0,
                      color: palette[i % palette.count])
        }
    }

    var body: some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .global)
            let o = CGPoint(x: globalOrigin.x - frame.minX, y: globalOrigin.y - frame.minY)
            TimelineView(.animation) { tl in
                let raw = tl.date.timeIntervalSince(start) / duration
                let t = min(1.0, max(0.0, raw))
                let ease = 1 - pow(1 - t, 3)
                Canvas { ctx, size in
                    let unit = min(size.width, size.height)
                    for s in stars {
                        let dist = CGFloat(ease) * s.distance * unit
                        let x = o.x + CGFloat(cos(s.angle)) * dist
                        let y = o.y + CGFloat(sin(s.angle)) * dist
                        let scale = s.size * CGFloat(1 - t * 0.2)
                        let level = max(0.0, sin(.pi * t)) * 0.9
                        drawTwinkle(&ctx, at: CGPoint(x: x, y: y), color: s.color,
                                    size: 4.6 * scale, level: level)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
