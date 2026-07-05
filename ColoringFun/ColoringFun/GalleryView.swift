import SwiftUI

private let bgGradient = LinearGradient(
    colors: [Color(red: 1.0, green: 0.97, blue: 0.86), Color(red: 0.86, green: 0.95, blue: 1.0)],
    startPoint: .top, endPoint: .bottom)

private let inkColor = Color(red: 0.32, green: 0.30, blue: 0.45)

/// Home screen: the themed categories (Animals, Birds, Fairy, Princess).
struct GalleryView: View {
    @State private var showPro = false
    @ObservedObject private var pro = ProStore.shared
    @State private var goCategory: Category?
    @State private var bursting = false
    @State private var burstOrigin: CGPoint = .zero
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 18)]

    var body: some View {
        NavigationStack {
            ScrollView {
                createOwnSection
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(Categories.all) { category in
                        CategoryCard(category: category)
                            .contentShape(Rectangle())
                            .gesture(SpatialTapGesture(coordinateSpace: .global).onEnded { value in
                                burstOrigin = value.location
                                burstThenOpen { goCategory = category }
                            })
                    }
                }
                .padding(18)
            }
            .background(bgGradient.ignoresSafeArea())
            .navigationDestination(item: $goCategory) { CategoryPagesView(category: $0) }
            .overlay { if bursting { StarBurst(globalOrigin: burstOrigin) } }
            .navigationTitle("Coloring Fun")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showPro = true } label: {
                        Image(systemName: "crown.fill").cuteCircle(Candy.orange)
                    }
                    .accessibilityLabel("Coloring Fun Pro")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        MyDrawingsView()
                    } label: {
                        Image(systemName: "photo.stack.fill").cuteCircle(Candy.purple)
                    }
                }
            }
            .sheet(isPresented: $showPro) { ProUnlockView() }
        }
    }

    /// Plays the star-burst + haptic + sound, then opens after a short beat.
    private func burstThenOpen(_ open: @escaping () -> Void) {
        TapFX.play()
        bursting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            open()
            bursting = false
        }
    }

    /// Pro-only "Create Your Own Drawing" banner. Unlocked users open the blank
    /// canvas; everyone else is shown the Pro page.
    @ViewBuilder private var createOwnSection: some View {
        if pro.isUnlocked {
            NavigationLink {
                CreateDrawingView()
            } label: {
                ProBannerCard(emoji: "🎨", title: "Create Your Own Drawing",
                              subtitle: "Draw with ✏️ pen, 🖌️ brush & 🖍️ crayon",
                              colors: [Candy.purple, Candy.pink], locked: false)
            }
            .buttonStyle(.plain)
        } else {
            Button { showPro = true } label: {
                ProBannerCard(emoji: "🎨", title: "Create Your Own Drawing",
                              subtitle: "Draw with ✏️ pen, 🖌️ brush & 🖍️ crayon",
                              colors: [Candy.purple, Candy.pink], locked: true)
            }
            .buttonStyle(.plain)
        }
    }
}

/// A colourful Pro banner that launches a feature (or the Pro page if locked).
private struct ProBannerCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    let colors: [Color]
    let locked: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(.white.opacity(0.25)).frame(width: 60, height: 60)
                Text(emoji).font(.system(size: 32))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer(minLength: 0)
            Image(systemName: locked ? "crown.fill" : "chevron.right.circle.fill")
                .font(.system(size: locked ? 22 : 26, weight: .black))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white, lineWidth: 4))
        .shadow(color: (colors.first ?? .clear).opacity(0.35), radius: 6, y: 3)
    }
}

/// The pictures inside one category.
struct CategoryPagesView: View {
    let category: Category
    @ObservedObject private var pro = ProStore.shared
    @State private var showPro = false
    @State private var goItem: CategoryItem?
    @State private var bursting = false
    @State private var burstOrigin: CGPoint = .zero
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 18)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(category.items) { item in
                    let locked = item.isPro && !pro.isUnlocked
                    if locked {
                        Button { showPro = true } label: { card(item, locked: true) }
                            .buttonStyle(.plain)
                    } else {
                        card(item, locked: false)
                            .contentShape(Rectangle())
                            .gesture(SpatialTapGesture(coordinateSpace: .global).onEnded { value in
                                burstOrigin = value.location
                                TapFX.play()
                                bursting = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                    goItem = item
                                    bursting = false
                                }
                            })
                    }
                }
            }
            .padding(18)
        }
        .background(bgGradient.ignoresSafeArea())
        .navigationDestination(item: $goItem) { destination($0) }
        .overlay { if bursting { StarBurst(globalOrigin: burstOrigin) } }
        .navigationTitle("\(category.emoji) \(category.name)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPro) { ProUnlockView() }
    }

    @ViewBuilder private func destination(_ item: CategoryItem) -> some View {
        switch item {
        case .vector(let page): ColoringScreen(page: page)
        case .image(let page): ImageColoringScreen(page: page)
        }
    }

    @ViewBuilder private func card(_ item: CategoryItem, locked: Bool) -> some View {
        switch item {
        case .vector(let page): PageCard(page: page)
        case .image(let page): ImagePageCard(page: page, locked: locked)
        }
    }
}

// MARK: - Cards

private struct CategoryCard: View {
    let category: Category

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 26).fill(category.tint)
                if let thumb = category.thumbnail {
                    Image(thumb)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    Text(category.emoji).font(.system(size: 76))
                }
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white, lineWidth: 5))
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)

            Text(category.name)
                .font(.title3.bold())
                .foregroundStyle(inkColor)
            Text("\(category.items.count) pictures")
                .font(.caption).foregroundStyle(inkColor.opacity(0.7))
        }
    }
}

private struct PageCard: View {
    let page: ColoringPage

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(page.cardTint)
                MiniPreview(page: page).padding(14)
            }
            .frame(height: 150)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white, lineWidth: 4))
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)

            Text("\(page.emoji)  \(page.title)")
                .font(.headline.bold())
                .foregroundStyle(inkColor)
        }
    }
}

/// Card for an image-backed picture: shows the real outline thumbnail.
private struct ImagePageCard: View {
    let page: ImagePage
    var locked = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(page.cardTint)
                Image(page.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(10)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .overlay(alignment: .topTrailing) {
                if locked {
                    // Small corner badge so the picture stays fully visible.
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill").font(.system(size: 10, weight: .black))
                        Text("PRO").font(.system(size: 11, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(colors: [Candy.purple, Candy.pink],
                                       startPoint: .leading, endPoint: .trailing),
                        in: Capsule())
                    .overlay(Capsule().stroke(.white, lineWidth: 1.5))
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    .padding(8)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white, lineWidth: 4))
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)

            Text("\(page.emoji)  \(page.title)")
                .font(.headline.bold())
                .foregroundStyle(inkColor)
        }
    }
}

/// Outline-only thumbnail so the child can recognise the picture.
private struct MiniPreview: View {
    let page: ColoringPage

    var body: some View {
        Canvas { ctx, size in
            let layout = Layout(canvas: page.canvas, view: size)
            for region in page.regions {
                let p = region.path.applying(layout.transform)
                ctx.fill(p, with: .color(.white.opacity(0.6)))
                ctx.stroke(p, with: .color(inkColor),
                           style: StrokeStyle(lineWidth: 1.4, lineJoin: .round))
            }
            if let deco = page.decorations {
                ctx.stroke(deco.applying(layout.transform), with: .color(inkColor),
                           style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
            }
        }
    }
}
