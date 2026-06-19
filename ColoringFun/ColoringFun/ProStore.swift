import SwiftUI

/// Tracks whether Coloring Fun Pro is unlocked (persisted locally).
final class ProStore: ObservableObject {
    static let shared = ProStore()
    private let key = "proUnlocked"
    private let planKey = "proPlan"

    @Published var isUnlocked: Bool {
        didSet { UserDefaults.standard.set(isUnlocked, forKey: key) }
    }

    /// The plan the user subscribed to (for display only).
    @Published var planName: String {
        didSet { UserDefaults.standard.set(planName, forKey: planKey) }
    }

    init() {
        isUnlocked = UserDefaults.standard.bool(forKey: key)
        planName = UserDefaults.standard.string(forKey: planKey) ?? ""
    }

    func unlock(plan: ProPlan) {
        planName = plan.title
        isUnlocked = true
    }
}

/// A Pro subscription option.
struct ProPlan: Identifiable, Equatable {
    let id: String
    let title: String          // e.g. "Yearly"
    let price: String          // e.g. "₹594"
    let period: String         // e.g. "per year"
    let subtitle: String?      // e.g. "Just ₹49.50 / month"
    let badge: String?         // e.g. "50% OFF"

    static let monthly = ProPlan(
        id: "monthly", title: "Monthly", price: "₹99", period: "per month",
        subtitle: "Billed every month", badge: nil)

    static let yearly = ProPlan(
        id: "yearly", title: "Yearly", price: "₹594", period: "per year",
        subtitle: "Just ₹49.50 / month", badge: "50% OFF")

    static let all: [ProPlan] = [.yearly, .monthly]
}

/// One feature highlighted on the Pro page.
private struct ProFeature: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}

private let proFeatures: [ProFeature] = [
    ProFeature(icon: "pencil.and.outline", text: "Create your own drawings — pen, brush & crayon"),
    ProFeature(icon: "crown.fill", text: "Exclusive Pro pictures — fairies, unicorns & more"),
    ProFeature(icon: "paintpalette.fill", text: "Soft pastel colour palette"),
    ProFeature(icon: "sparkles", text: "Sparkly glitter & shiny brushes"),
    ProFeature(icon: "square.and.arrow.down.fill", text: "Save & share your art in HD"),
    ProFeature(icon: "hand.thumbsup.fill", text: "No ads — just happy colouring"),
]

/// The Pro page: shows features and the monthly / yearly subscription plans.
struct ProUnlockView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var pro = ProStore.shared
    @State private var selected: ProPlan = .yearly

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.92),
                                    Color(red: 0.93, green: 0.95, blue: 1.0)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if pro.isUnlocked {
                unlockedState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        featureList
                        VStack(spacing: 12) {
                            ForEach(ProPlan.all) { plan in
                                PlanRow(plan: plan, isSelected: selected == plan) {
                                    selected = plan
                                }
                            }
                        }
                        .padding(.horizontal, 22)
                        subscribeButton
                        Text("Cancel anytime. Subscription unlocks every Pro feature.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Candy.ink.opacity(0.5))
                            .padding(.horizontal, 30)
                        Button("Maybe later") { dismiss() }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Candy.ink.opacity(0.6))
                            .padding(.bottom, 16)
                    }
                    .padding(.top, 18)
                }
            }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Candy.yellow, Candy.orange],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 84, height: 84)
                    .shadow(color: Candy.orange.opacity(0.4), radius: 6, y: 3)
                Image(systemName: "crown.fill")
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(.white)
            }
            Text("Coloring Fun Pro")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Candy.ink)
            Text("Unlock everything and make colouring even more magical")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Candy.ink.opacity(0.7))
                .padding(.horizontal, 34)
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(proFeatures) { feature in
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Candy.purple.opacity(0.15)).frame(width: 38, height: 38)
                        Image(systemName: feature.icon)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Candy.purple)
                    }
                    Text(feature.text)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Candy.ink)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(20)
        .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal, 22)
    }

    private var subscribeButton: some View {
        Button {
            pro.unlock(plan: selected)
        } label: {
            Text("Subscribe \(selected.title) • \(selected.price)")
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
        .padding(.horizontal, 22)
    }

    private var unlockedState: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Candy.yellow, Candy.orange],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 100, height: 100)
                Image(systemName: "crown.fill")
                    .font(.system(size: 46, weight: .black))
                    .foregroundStyle(.white)
            }
            .shadow(color: Candy.orange.opacity(0.4), radius: 6, y: 3)
            Text("You're Pro! 🎉")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Candy.ink)
            Text(pro.planName.isEmpty
                 ? "Every Pro feature is unlocked."
                 : "\(pro.planName) plan active — every Pro feature is unlocked.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Candy.ink.opacity(0.7))
                .padding(.horizontal, 34)
            Spacer()
            Button("Done") { dismiss() }
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient(colors: [Candy.pink, Candy.purple],
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 22))
                .padding(.horizontal, 22)
                .padding(.bottom, 20)
        }
    }
}

/// A selectable subscription plan row.
private struct PlanRow: View {
    let plan: ProPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isSelected ? Candy.purple : Candy.ink.opacity(0.3))

                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.title)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(Candy.ink)
                    if let subtitle = plan.subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Candy.ink.opacity(0.6))
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 3) {
                    if let badge = plan.badge {
                        Text(badge)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Candy.green, in: Capsule())
                    }
                    Text(plan.price)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(Candy.ink)
                    Text(plan.period)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Candy.ink.opacity(0.6))
                }
            }
            .padding(16)
            .background(.white.opacity(isSelected ? 0.95 : 0.6),
                        in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Candy.purple : .clear, lineWidth: 3)
            )
            .shadow(color: .black.opacity(isSelected ? 0.12 : 0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}
