import SwiftUI

/// Home screen: a playful grid of pictures the child can pick to colour.
struct GalleryView: View {
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 18)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(Pages.all) { page in
                        NavigationLink {
                            ColoringScreen(page: page)
                        } label: {
                            PageCard(page: page)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
            .background(
                LinearGradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.86),
                                        Color(red: 0.86, green: 0.95, blue: 1.0)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("Coloring Fun")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// A single picture tile in the gallery.
private struct PageCard: View {
    let page: ColoringPage

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(page.cardTint)
                MiniPreview(page: page)
                    .padding(14)
            }
            .frame(height: 150)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white, lineWidth: 4)
            )
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)

            Text("\(page.emoji)  \(page.title)")
                .font(.headline.bold())
                .foregroundStyle(Color(red: 0.32, green: 0.30, blue: 0.45))
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
                ctx.fill(p, with: .color(.white.opacity(0.65)))
                ctx.stroke(p, with: .color(Color(red: 0.32, green: 0.30, blue: 0.45)),
                           style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))
            }
        }
    }
}
