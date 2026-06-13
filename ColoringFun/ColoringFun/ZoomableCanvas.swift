import SwiftUI

/// The aspect-fit rectangle of `aspect` (w/h) centred inside `size`.
func aspectFitRect(aspect: CGFloat, in size: CGSize) -> CGRect {
    var w = size.width
    var h = w / max(aspect, 0.0001)
    if h > size.height { h = size.height; w = h * aspect }
    return CGRect(x: (size.width - w) / 2, y: (size.height - h) / 2, width: w, height: h)
}

/// Adds pinch-to-zoom, drag-to-pan and ＋/－ zoom buttons around a colouring
/// surface. A short tap (little movement) is reported through `onTap` with the
/// tap location plus the current zoom scale and pan offset, so the caller can
/// map the point back into the picture.
struct ZoomableColoring: ViewModifier {
    let onTap: (_ point: CGPoint, _ size: CGSize, _ scale: CGFloat, _ offset: CGSize) -> Void

    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var dragTranslation: CGSize = .zero

    private let maxScale: CGFloat = 5

    func body(content: Content) -> some View {
        GeometryReader { geo in
            let liveScale = min(max(scale * pinch, 1), maxScale)
            let liveOffset = liveScale > 1
                ? CGSize(width: offset.width + dragTranslation.width,
                         height: offset.height + dragTranslation.height)
                : .zero
            ZStack {
                content
                    .scaleEffect(liveScale)
                    .offset(liveOffset)
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(gesture(geo: geo))
                controls
            }
            .clipped()
        }
    }

    private func gesture(geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragTranslation) { value, state, _ in state = value.translation }
            .onEnded { value in
                let moved = hypot(value.translation.width, value.translation.height)
                if moved < 12 {
                    onTap(value.location, geo.size, scale, scale > 1 ? offset : .zero)
                } else if scale > 1 {
                    offset = CGSize(width: offset.width + value.translation.width,
                                    height: offset.height + value.translation.height)
                }
            }
            .simultaneously(with:
                MagnifyGesture()
                    .updating($pinch) { value, state, _ in state = value.magnification }
                    .onEnded { value in
                        scale = min(max(scale * value.magnification, 1), maxScale)
                        if scale <= 1.01 { scale = 1; offset = .zero }
                    }
            )
    }

    private var controls: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 10) {
                    zoomButton("plus.magnifyingglass") { setScale(scale + 0.6) }
                    zoomButton("minus.magnifyingglass") { setScale(scale - 0.6) }
                    zoomButton("arrow.counterclockwise") { scale = 1; offset = .zero }
                }
                .padding(12)
            }
        }
    }

    private func zoomButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3.bold())
                .foregroundStyle(Color(red: 0.32, green: 0.30, blue: 0.45))
                .frame(width: 44, height: 44)
                .background(Circle().fill(.white.opacity(0.92)))
                .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func setScale(_ s: CGFloat) {
        scale = min(max(s, 1), maxScale)
        if scale == 1 { offset = .zero }
    }
}

extension View {
    func zoomableColoring(
        onTap: @escaping (_ point: CGPoint, _ size: CGSize, _ scale: CGFloat, _ offset: CGSize) -> Void
    ) -> some View {
        modifier(ZoomableColoring(onTap: onTap))
    }
}
