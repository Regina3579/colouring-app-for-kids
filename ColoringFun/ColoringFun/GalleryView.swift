import SwiftUI

private let bgGradient = LinearGradient(
    colors: [Color(red: 1.0, green: 0.97, blue: 0.86), Color(red: 0.86, green: 0.95, blue: 1.0)],
    startPoint: .top, endPoint: .bottom)

private let inkColor = Color(red: 0.32, green: 0.30, blue: 0.45)

/// Home screen: the themed categories (Animals, Birds, Fairy, Princess).
struct GalleryView: View {
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 18)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(Categories.all) { category in
                        NavigationLink {
                            CategoryPagesView(category: category)
                        } label: {
                            CategoryCard(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
            .background(bgGradient.ignoresSafeArea())
            .navigationTitle("Coloring Fun")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        MyDrawingsView()
                    } label: {
                        Image(systemName: "photo.stack.fill").cuteCircle(Candy.purple)
                    }
                }
            }
        }
    }
}

/// The pictures inside one category.
struct CategoryPagesView: View {
    let category: Category
    @ObservedObject private var pro = ProStore.shared
    @State private var showPro = false
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
                        NavigationLink {
                            destination(item)
                        } label: {
                            card(item, locked: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(18)
        }
        .background(bgGradient.ignoresSafeArea())
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
                    .opacity(locked ? 0.55 : 1)
                if locked {
                    ZStack {
                        Circle().fill(Candy.purple)
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(.white, lineWidth: 3))
                        Image(systemName: "crown.fill")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                }
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
