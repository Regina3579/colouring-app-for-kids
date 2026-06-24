import SwiftUI
import StoreKit

// MARK: - Legal links shown on the Pro page (Apple requires functional links)

enum ProLinks {
    // ‼️ REPLACE these with your real hosted pages before submitting to review.
    static let privacy = URL(string: "https://example.com/privacy")!
    static let terms   = URL(string: "https://example.com/terms")!
}

/// Unlocks "Coloring Fun Pro" via real StoreKit auto-renewable subscriptions.
/// `isUnlocked` reflects the App Store entitlement (not a local flag), so it
/// survives reinstalls and works across the user's devices.
@MainActor
final class ProStore: ObservableObject {
    static let shared = ProStore()

    static let monthlyID = "com.kidscoloring.ColoringFun.pro.monthly"
    static let yearlyID  = "com.kidscoloring.ColoringFun.pro.yearly"
    static let productIDs = [yearlyID, monthlyID]

    @Published private(set) var isUnlocked = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoadingProducts = false
    @Published var purchaseError: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    func product(for id: String) -> Product? { products.first { $0.id == id } }

    /// Fetches the subscription products from the App Store.
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let fetched = try await Product.products(for: Self.productIDs)
            // Keep our preferred order (yearly first, then monthly).
            products = Self.productIDs.compactMap { id in fetched.first { $0.id == id } }
        } catch {
            purchaseError = "Couldn't load subscriptions. Please check your connection and try again."
        }
    }

    /// Starts a purchase for the given product.
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = "Purchase couldn't be completed. Please try again."
        }
    }

    /// Restores previous purchases (required by App Review).
    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            // A cancelled sync throws — nothing to report.
        }
        await refreshEntitlements()
        if !isUnlocked {
            purchaseError = "No active subscription was found to restore."
        }
    }

    /// Recomputes `isUnlocked` from the current App Store entitlements.
    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               Self.productIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                active = true
            }
        }
        isUnlocked = active
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? self.checkVerified(update) {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe): return safe
        case .unverified:         throw StoreError.failedVerification
        }
    }

    enum StoreError: Error { case failedVerification }
}

// MARK: - A Pro subscription option (display + product id)

struct ProPlan: Identifiable, Equatable {
    let id: String             // == StoreKit product id
    let title: String          // e.g. "Yearly"
    let fallbackPrice: String  // shown until StoreKit prices load
    let period: String         // e.g. "per year"
    let subtitle: String?
    let badge: String?

    static let monthly = ProPlan(
        id: ProStore.monthlyID, title: "Monthly", fallbackPrice: "₹99",
        period: "per month", subtitle: "Billed every month", badge: nil)

    static let yearly = ProPlan(
        id: ProStore.yearlyID, title: "Yearly", fallbackPrice: "₹594",
        period: "per year", subtitle: "Just ₹49.50 / month", badge: "50% OFF")

    static let all: [ProPlan] = [.yearly, .monthly]
}

// MARK: - Feature list

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

// MARK: - The Pro page

struct ProUnlockView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var pro = ProStore.shared
    @State private var selected: ProPlan = .yearly
    @State private var working = false

    private func price(for plan: ProPlan) -> String {
        pro.product(for: plan.id)?.displayPrice ?? plan.fallbackPrice
    }

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
                    VStack(spacing: 18) {
                        header
                        featureList
                        VStack(spacing: 12) {
                            ForEach(ProPlan.all) { plan in
                                PlanRow(plan: plan, price: price(for: plan),
                                        isSelected: selected == plan) { selected = plan }
                            }
                        }
                        .padding(.horizontal, 22)

                        subscribeButton

                        Button { Task { working = true; await pro.restore(); working = false } } label: {
                            Text("Restore Purchases")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(Candy.purple)
                        }
                        .disabled(working)

                        legalText
                    }
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                }
                .overlay { if working { ProgressView().scaleEffect(1.4) } }
            }
        }
        .alert("Oops", isPresented: Binding(get: { pro.purchaseError != nil },
                                            set: { if !$0 { pro.purchaseError = nil } })) {
            Button("OK", role: .cancel) { pro.purchaseError = nil }
        } message: {
            Text(pro.purchaseError ?? "")
        }
    }

    // MARK: Pieces

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
            guard let product = pro.product(for: selected.id) else { return }
            working = true
            Task { await pro.purchase(product); working = false }
        } label: {
            Group {
                if pro.isLoadingProducts && pro.product(for: selected.id) == nil {
                    Text("Loading…")
                } else {
                    Text("Subscribe \(selected.title) • \(price(for: selected))")
                }
            }
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
        .disabled(working || pro.product(for: selected.id) == nil)
        .opacity(pro.product(for: selected.id) == nil ? 0.6 : 1)
        .padding(.horizontal, 22)
    }

    /// Auto-renew disclosure + required Privacy Policy / Terms links.
    private var legalText: some View {
        VStack(spacing: 8) {
            Text("Payment is charged to your Apple ID at confirmation of purchase. The subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in your Apple ID Account Settings.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Candy.ink.opacity(0.55))

            HStack(spacing: 18) {
                Link("Privacy Policy", destination: ProLinks.privacy)
                Text("•").foregroundStyle(Candy.ink.opacity(0.4))
                Link("Terms of Use", destination: ProLinks.terms)
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(Candy.purple)

            Button("Maybe later") { dismiss() }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Candy.ink.opacity(0.6))
                .padding(.top, 4)
        }
        .padding(.horizontal, 28)
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
            Text("Every Pro feature is unlocked. Thank you for supporting Coloring Fun!")
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
    let price: String
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
                    Text(price)
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
