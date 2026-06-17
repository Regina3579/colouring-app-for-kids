import SwiftUI

private struct ConfettiPiece {
    var x: CGFloat        // start position 0...1
    var color: Color
    var size: CGFloat
    var speed: CGFloat
    var sway: CGFloat
    var phase: CGFloat
    var spin: CGFloat
    var isStar: Bool

    static func random() -> ConfettiPiece {
        let colors: [Color] = [Candy.pink, Candy.blue, Candy.yellow, Candy.green,
                               Candy.purple, Candy.orange, Candy.teal, Candy.red]
        return ConfettiPiece(
            x: .random(in: 0...1),
            color: colors.randomElement()!,
            size: .random(in: 9...18),
            speed: .random(in: 0.45...1.05),
            sway: .random(in: 2...5),
            phase: .random(in: 0...6.28),
            spin: .random(in: -7...7),
            isStar: Bool.random())
    }
}

/// A round green tick kids tap at the top corner of the picture when they're
/// finished — it sets off the confetti + happy dance celebration.
struct DoneTickButton: View {
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "checkmark")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(Circle().fill((enabled ? Candy.green : Color.gray.opacity(0.45)).gradient))
                .overlay(Circle().stroke(.white, lineWidth: 4))
                .shadow(color: (enabled ? Candy.green : .clear).opacity(0.5), radius: 5, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel("Done")
    }
}

/// A cheerful burst of confetti + "Beautiful!" banner shown when a picture is done.
struct CelebrationOverlay: View {
    @State private var start = Date()
    @State private var bannerIn = false
    private let pieces = (0..<70).map { _ in ConfettiPiece.random() }

    var body: some View {
        ZStack {
            TimelineView(.animation) { timeline in
                let t = CGFloat(timeline.date.timeIntervalSince(start))
                Canvas { ctx, size in
                    for p in pieces {
                        let y = -30 + t * p.speed * (size.height + 80)
                        if y > size.height + 30 { continue }
                        let x = p.x * size.width + sin(t * p.sway + p.phase) * 26
                        let c = CGPoint(x: x, y: y)
                        let path = p.isStar
                            ? star5(x, y, p.size * 0.7)
                            : Path(roundedRect: CGRect(x: x - p.size / 2, y: y - p.size / 2,
                                                       width: p.size, height: p.size * 0.6),
                                   cornerRadius: 2)
                        ctx.drawLayer { layer in
                            layer.translateBy(x: c.x, y: c.y)
                            layer.rotate(by: .radians(Double(t * p.spin)))
                            layer.translateBy(x: -c.x, y: -c.y)
                            layer.fill(path, with: .color(p.color))
                        }
                    }
                }
            }
            .allowsHitTesting(false)

            VStack {
                Text("🎉 Beautiful! 🎉")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 14)
                    .background(LinearGradient(colors: [Candy.pink, Candy.purple],
                                               startPoint: .leading, endPoint: .trailing),
                                in: Capsule())
                    .shadow(color: Candy.purple.opacity(0.4), radius: 6, y: 3)
                    .scaleEffect(bannerIn ? 1 : 0.4)
                    .opacity(bannerIn ? 1 : 0)
                    .rotationEffect(.degrees(bannerIn ? 0 : -8))
                Spacer()
            }
            .padding(.top, 40)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) { bannerIn = true }
        }
    }
}

/// Drives a short happy wiggle/bounce ("dance") on a finished picture.
struct DanceModifier: ViewModifier {
    let dancing: Bool
    @State private var angle: Double = 0
    @State private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .scaleEffect(scale)
            .onChange(of: dancing) { _, isDancing in
                if isDancing { dance() }
            }
    }

    private func dance() {
        Task { @MainActor in
            for _ in 0..<5 {
                withAnimation(.easeInOut(duration: 0.16)) { angle = 5; scale = 1.05 }
                try? await Task.sleep(nanoseconds: 160_000_000)
                withAnimation(.easeInOut(duration: 0.16)) { angle = -5; scale = 1.03 }
                try? await Task.sleep(nanoseconds: 160_000_000)
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) { angle = 0; scale = 1 }
        }
    }
}

extension View {
    func danceWhenFinished(_ dancing: Bool) -> some View {
        modifier(DanceModifier(dancing: dancing))
    }
}
