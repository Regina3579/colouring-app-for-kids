import SwiftUI

private let bgGradient = LinearGradient(
    colors: [Color(red: 1.0, green: 0.97, blue: 0.86), Color(red: 0.86, green: 0.95, blue: 1.0)],
    startPoint: .top, endPoint: .bottom)
private let inkColor = Color(red: 0.32, green: 0.30, blue: 0.45)

/// The child's saved finished drawings.
struct MyDrawingsView: View {
    @ObservedObject private var store = DrawingsStore.shared
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 18)]

    var body: some View {
        ScrollView {
            if store.drawings.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(store.drawings) { drawing in
                        NavigationLink {
                            DrawingDetailView(drawing: drawing)
                        } label: {
                            DrawingCard(drawing: drawing)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
            }
        }
        .background(bgGradient.ignoresSafeArea())
        .navigationTitle("My Drawings")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { store.reload() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            CrayonRow()
                .frame(height: 90)
            Text("No drawings yet")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(inkColor)
            Text("Color a picture, then tap Save → \"Save to My Drawings.\"")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(inkColor.opacity(0.7))
                .padding(.horizontal, 40)
        }
        .padding(.top, 80)
    }
}

private struct DrawingCard: View {
    let drawing: SavedDrawing

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22).fill(.white)
            if let img = DrawingsStore.shared.image(drawing) {
                Image(uiImage: img).resizable().scaledToFit().padding(8)
            }
        }
        .frame(height: 160)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white, lineWidth: 4))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }
}

/// Full-screen view of one saved drawing with Share and Delete.
struct DrawingDetailView: View {
    let drawing: SavedDrawing
    @Environment(\.dismiss) private var dismiss
    @State private var showShare = false
    @State private var confirmDelete = false

    var body: some View {
        VStack {
            if let img = DrawingsStore.shared.image(drawing) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
        }
        .background(bgGradient.ignoresSafeArea())
        .navigationTitle("My Drawing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { showShare = true } label: {
                    Image(systemName: "square.and.arrow.up.fill").cuteCircle(Candy.blue)
                }
                Button(role: .destructive) { confirmDelete = true } label: {
                    Image(systemName: "trash.fill").cuteCircle(Candy.red)
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let img = DrawingsStore.shared.image(drawing) {
                ActivityView(items: [img])
            }
        }
        .alert("Delete this drawing?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                DrawingsStore.shared.delete(drawing)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
