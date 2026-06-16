import SwiftUI

/// Tracks whether the Pro pastel palette is unlocked (persisted locally).
final class ProStore: ObservableObject {
    static let shared = ProStore()
    private let key = "proUnlocked"

    @Published var isUnlocked: Bool {
        didSet { UserDefaults.standard.set(isUnlocked, forKey: key) }
    }

    init() { isUnlocked = UserDefaults.standard.bool(forKey: key) }

    func unlock() { isUnlocked = true }
}

/// A gentle, kid/parent-friendly screen to unlock the Pro pastel palette.
struct ProUnlockView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var pro = ProStore.shared
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 8)
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(LinearGradient(colors: [Candy.pink, Candy.purple, Candy.blue],
                                                startPoint: .leading, endPoint: .trailing))
            Text("Coloring Fun Pro")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Candy.ink)
            Text("Unlock elegant pastel colours and exclusive Pro pictures")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Candy.ink.opacity(0.7))
                .padding(.horizontal, 30)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Palette.pastels) { swatch in
                    SwatchShape(paint: swatch.paint)
                        .frame(height: 34)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
                }
            }
            .padding(.horizontal, 26)

            Spacer(minLength: 8)

            Button {
                pro.unlock(); dismiss()
            } label: {
                Text("✨ Unlock Pro")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(colors: [Candy.pink, Candy.purple],
                                       startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 22))
                    .shadow(color: Candy.purple.opacity(0.4), radius: 5, y: 3)
            }
            .padding(.horizontal, 26)

            Button("Maybe later") { dismiss() }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Candy.ink.opacity(0.6))
                .padding(.bottom, 10)
        }
        .background(
            LinearGradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.92),
                                    Color(red: 0.93, green: 0.95, blue: 1.0)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
}
