import SwiftUI
import PhotosUI
import CoreImage
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Turn a photo into a black-outline colouring page

enum PhotoOutline {
    /// Converts an uploaded photo into a clean black-on-white outline (like a
    /// colouring book page) using on-device edge detection.
    static func make(from input: UIImage, maxDim: CGFloat = 1400) -> UIImage? {
        // Normalise orientation + size in a single redraw onto a white page.
        let m = max(input.size.width, input.size.height)
        let factor = m > maxDim ? maxDim / m : 1
        let target = CGSize(width: max(1, input.size.width * factor),
                            height: max(1, input.size.height * factor))
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.scale = 1; fmt.opaque = true
        let base = UIGraphicsImageRenderer(size: target, format: fmt).image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: target))
            input.draw(in: CGRect(origin: .zero, size: target))
        }

        guard let ci = CIImage(image: base) else { return nil }
        let context = CIContext(options: nil)
        let extent = ci.extent

        let blurred = ci.applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 1.4])
            .cropped(to: extent)
        let mono = blurred.applyingFilter("CIPhotoEffectNoir")
        let edges = mono.applyingFilter("CIEdges", parameters: [kCIInputIntensityKey: 2.5])
        let inverted = edges.applyingFilter("CIColorInvert")
        let crisp = inverted.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.0,
            kCIInputContrastKey: 6.0,
            kCIInputBrightnessKey: 0.06,
        ])
        let thick = crisp.applyingFilter("CIMorphologyMinimum", parameters: [kCIInputRadiusKey: 1.2])
            .cropped(to: extent)

        guard let cg = context.createCGImage(thick, from: extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

// MARK: - Pick a photo, make the outline, then colour it

struct PhotoColoringScreen: View {
    @State private var pickerItem: PhotosPickerItem?
    @State private var outline: UIImage?
    @State private var processing = false
    @State private var failed = false

    var body: some View {
        Group {
            if let outline {
                PhotoColorCanvas(outline: outline) { reset() }
            } else {
                chooser
            }
        }
        .navigationTitle("📷 Color My Photo")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var chooser: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(LinearGradient(colors: [Candy.pink, Candy.purple],
                                             startPoint: .top, endPoint: .bottom))
                    .frame(width: 110, height: 110)
                    .shadow(color: Candy.purple.opacity(0.4), radius: 6, y: 3)
                Image(systemName: "photo.badge.plus.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text("Color My Photo")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Candy.ink)
            Text("Pick a photo and we'll turn it into a black-and-white outline you can colour in!")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Candy.ink.opacity(0.7))
                .padding(.horizontal, 36)

            if processing {
                ProgressView("Making your outline…")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .padding(.top, 6)
            } else {
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    Text("📷 Choose a Photo")
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(colors: [Candy.pink, Candy.purple],
                                           startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 22))
                            .shadow(color: Candy.purple.opacity(0.4), radius: 5, y: 3)
                        .padding(.horizontal, 30)
                }
            }

            if failed {
                Text("Sorry, that photo couldn't be used. Please try another one.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Candy.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
            Spacer()
        }
        .background(
            LinearGradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.86),
                                    Color(red: 0.86, green: 0.95, blue: 1.0)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .onChange(of: pickerItem) { _, item in loadPhoto(item) }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        processing = true; failed = false
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            let result: UIImage? = {
                guard let data, let ui = UIImage(data: data) else { return nil }
                return PhotoOutline.make(from: ui)
            }()
            await MainActor.run {
                processing = false
                if let result { outline = result } else { failed = true }
            }
        }
    }

    private func reset() {
        outline = nil
        pickerItem = nil
        failed = false
    }
}

// MARK: - The colouring surface for a generated photo outline

private struct PhotoColorCanvas: View {
    @StateObject private var model: FloodFillModel
    let onNewPhoto: () -> Void

    @State private var selectedPaint: Paint = Palette.defaultPaint
    @State private var selectedSwatchID: String = Palette.defaultID
    @State private var tool: Tool = .bucket
    @State private var shareItem: ShareItem?
    @State private var savedAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isReplaying = false
    @State private var celebrating = false

    init(outline: UIImage, onNewPhoto: @escaping () -> Void) {
        _model = StateObject(wrappedValue: FloodFillModel(image: outline))
        self.onNewPhoto = onNewPhoto
    }

    var body: some View {
        VStack(spacing: 0) {
            ImageColoringCanvas(model: model, selectedPaint: selectedPaint, tool: tool)
                .danceWhenFinished(celebrating)
                .allowsHitTesting(!isReplaying)
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white, lineWidth: 6))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .overlay(alignment: .topTrailing) {
                    DoneTickButton(enabled: model.hasPaint && !isReplaying, action: startCelebration)
                        .padding(18)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ToolBar(tool: $tool, onUndo: model.undo, onRedo: model.redo,
                    onClear: model.clear, onReplay: replay,
                    canUndo: model.canUndo, canRedo: model.canRedo,
                    canReplay: model.canReplay, isReplaying: isReplaying)
                .padding(.vertical, 10)

            PaletteBar(selectedPaint: $selectedPaint, selectedSwatchID: $selectedSwatchID)
                .padding(.bottom, 8)
        }
        .background(
            LinearGradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.86),
                                    Color(red: 0.86, green: 0.95, blue: 1.0)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .overlay { if celebrating { CelebrationOverlay() } }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: onNewPhoto) {
                    Image(systemName: "photo.badge.plus.fill").cuteCircle(Candy.orange)
                }
                Menu {
                    Button { saveToDrawings() } label: {
                        Label("Save to My Drawings", systemImage: "photo.stack.fill")
                    }
                    Button { saveToPhotos() } label: {
                        Label("Save to Photos", systemImage: "photo")
                    }
                } label: {
                    Image(systemName: "tray.and.arrow.down.fill").cuteCircle(Candy.green)
                }
                Button { share() } label: {
                    Image(systemName: "square.and.arrow.up.fill").cuteCircle(Candy.blue)
                }
            }
        }
        .sheet(item: $shareItem) { item in ActivityView(items: [item.image]) }
        .alert(alertTitle, isPresented: $savedAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text(alertMessage) }
    }

    private func startCelebration() {
        guard !celebrating else { return }
        guard model.paintedFraction() >= 0.5 else {
            alertTitle = "Almost there! 🎨"
            alertMessage = "Colour a little more of your picture, then tap the ✓ to celebrate!"
            savedAlert = true
            return
        }
        celebrating = true
        Haptics.tap()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation { celebrating = false }
        }
    }

    private func replay() {
        let ops = model.replayOps()
        guard !ops.isEmpty, !isReplaying else { return }
        isReplaying = true
        model.clearCanvasForReplay()
        Task { @MainActor in
            for op in ops {
                model.replayApply(op)
                Haptics.tap()
                try? await Task.sleep(nanoseconds: 320_000_000)
            }
            isReplaying = false
        }
    }

    private func saveToDrawings() {
        let ok = DrawingsStore.shared.save(model.exportImage())
        alertTitle = ok ? "Saved!" : "Couldn't Save"
        alertMessage = ok ? "Your drawing was added to My Drawings." : "Something went wrong saving."
        savedAlert = true
    }

    private func saveToPhotos() {
        PhotoSaver.shared.save(model.exportImage()) { ok in
            alertTitle = ok ? "Saved to Photos!" : "Couldn't Save"
            alertMessage = ok ? "Your picture was added to your photos."
                              : "Please allow photo access in Settings to save."
            savedAlert = true
        }
    }

    private func share() {
        shareItem = ShareItem(image: model.exportImage())
    }
}
