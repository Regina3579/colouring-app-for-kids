import SwiftUI

/// The full colouring experience for one picture: canvas + tools + colours.
struct ColoringScreen: View {
    let page: ColoringPage

    @State private var fills: [Int: Fill] = [:]
    @State private var history: [(Int, Fill?)] = []
    @State private var selectedColor: Color = Palette.swatches[1].color
    @State private var selectedSwatch: UUID = Palette.swatches[1].id
    @State private var tool: Tool = .bucket

    var body: some View {
        VStack(spacing: 0) {
            ColoringCanvasView(page: page,
                               selectedColor: selectedColor,
                               tool: tool,
                               fills: $fills,
                               history: $history)
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white, lineWidth: 6))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ToolBar(tool: $tool, onUndo: undo, onClear: clearAll)
                .padding(.vertical, 10)

            PaletteBar(selectedColor: $selectedColor, selectedSwatch: $selectedSwatch)
                .padding(.bottom, 8)
        }
        .background(
            LinearGradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.86),
                                    Color(red: 0.86, green: 0.95, blue: 1.0)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .navigationTitle("\(page.emoji) \(page.title)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func undo() {
        guard let (id, previous) = history.popLast() else { return }
        fills[id] = previous
        Haptics.tap()
    }

    private func clearAll() {
        guard !fills.isEmpty else { return }
        fills = [:]
        history = []
        Haptics.tap()
    }
}

// MARK: - Tool buttons + undo / clear

private struct ToolBar: View {
    @Binding var tool: Tool
    let onUndo: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Tool.allCases) { t in
                Button { tool = t } label: {
                    VStack(spacing: 2) {
                        Image(systemName: t.icon).font(.title2)
                        Text(t.title).font(.caption2.bold())
                    }
                    .frame(width: 62, height: 56)
                    .foregroundStyle(tool == t ? .white : Color(red: 0.32, green: 0.30, blue: 0.45))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(tool == t ? Color(red: 0.42, green: 0.55, blue: 0.95) : .white)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 4)

            roundButton(system: "arrow.uturn.backward", tint: Color(red: 0.42, green: 0.55, blue: 0.95), action: onUndo)
            roundButton(system: "trash", tint: Color(red: 0.98, green: 0.45, blue: 0.45), action: onClear)
        }
        .padding(.horizontal, 14)
    }

    private func roundButton(system: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(width: 50, height: 56)
                .background(RoundedRectangle(cornerRadius: 16).fill(tint))
                .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Colour swatches

private struct PaletteBar: View {
    @Binding var selectedColor: Color
    @Binding var selectedSwatch: UUID

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(Palette.swatches) { swatch in
                    Button {
                        selectedColor = swatch.color
                        selectedSwatch = swatch.id
                    } label: {
                        Circle()
                            .fill(swatch.color)
                            .frame(width: 46, height: 46)
                            .overlay(Circle().stroke(.white, lineWidth: 4))
                            .overlay(
                                Circle().stroke(Color(red: 0.32, green: 0.30, blue: 0.45),
                                                lineWidth: selectedSwatch == swatch.id ? 3 : 0)
                                    .padding(-3)
                            )
                            .scaleEffect(selectedSwatch == swatch.id ? 1.18 : 1.0)
                            .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                            .animation(.spring(response: 0.3), value: selectedSwatch)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
        }
    }
}
