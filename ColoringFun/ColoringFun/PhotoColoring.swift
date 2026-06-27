import SwiftUI
import PhotosUI
import CoreImage
import CoreML
import Vision
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Turn a photo into a black-outline colouring page

enum PhotoOutline {
    /// Converts an uploaded photo into a clean, bold black-on-white outline
    /// (like a colouring book page) using on-device image processing.
    /// `boldness` ~0.6 (fine) … ~1.6 (very bold).
    static func make(from input: UIImage, maxDim: CGFloat = 1500, boldness: CGFloat = 1.1) -> UIImage? {
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

        // 1) Smooth away fine texture/noise so only the real shapes survive —
        //    this is what makes the lines clean instead of a scratchy sketch.
        let smoothed = ci
            .applyingFilter("CIMedianFilter")
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 2.2])
            .cropped(to: extent)

        // 2) Grayscale, then posterize to flatten gradients into a few flat
        //    tones — gives a cartoon look so edges land only on real outlines.
        let mono = smoothed.applyingFilter("CIPhotoEffectNoir")
        let flat = mono.applyingFilter("CIColorPosterize", parameters: ["inputLevels": 5.0])

        // 3) Detect edges and invert to black lines on white.
        let edges = flat.applyingFilter("CIEdges", parameters: [kCIInputIntensityKey: 1.6])
        let inverted = edges.applyingFilter("CIColorInvert")

        // 4) Hard threshold to crisp pure black/white.
        let crisp = inverted.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.0,
            kCIInputContrastKey: 14.0,
            kCIInputBrightnessKey: 0.12,
        ])

        // 5) Thicken & connect the lines for a nice bold colouring-book outline.
        let radius = max(1.0, 2.4 * boldness)
        let thick = crisp.applyingFilter("CIMorphologyMinimum", parameters: [kCIInputRadiusKey: radius])
            .cropped(to: extent)

        guard let cg = context.createCGImage(thick, from: extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

// MARK: - On-device AI line-art model (used automatically when bundled)

/// Runs a bundled Core ML image-to-image "line art" model to produce a clean,
/// bold outline — the same kind of result as the AI photo-to-colouring apps.
///
/// To enable AI quality, add a Core ML model named `PhotoLineArt` (an
/// `.mlpackage` or `.mlmodel`) to the app target. A good choice is the
/// "Informative Drawings" line-extraction model (image in → grayscale line
/// image out). Until then, the app falls back to `PhotoOutline` automatically.
enum PhotoOutlineAI {
    static let modelName = "PhotoLineArt"

    static var isAvailable: Bool {
        Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") != nil
    }

    static func make(from input: UIImage) async -> UIImage? {
        guard let url = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc"),
              let ml = try? MLModel(contentsOf: url),
              let vnModel = try? VNCoreMLModel(for: ml),
              let cg = normalized(input).cgImage else { return nil }

        let lines: CIImage? = await withCheckedContinuation { cont in
            let request = VNCoreMLRequest(model: vnModel) { req, _ in
                if let obs = req.results?.first as? VNPixelBufferObservation {
                    cont.resume(returning: CIImage(cvPixelBuffer: obs.pixelBuffer))
                } else {
                    cont.resume(returning: nil)
                }
            }
            // Stretch to the model's square input; we un-stretch the result
            // afterwards, which avoids padding bars turning into stray lines.
            request.imageCropAndScaleOption = .scaleFill
            let handler = VNImageRequestHandler(cgImage: cg, options: [:])
            do { try handler.perform([request]) } catch { cont.resume(returning: nil) }
        }
        guard let lines else { return nil }
        return postProcess(lines, like: input)
    }

    /// Cleans the model output into crisp bold black-on-white at the photo's aspect.
    private static func postProcess(_ output: CIImage, like original: UIImage) -> UIImage? {
        let context = CIContext(options: nil)
        var img = output.applyingFilter("CIPhotoEffectNoir")
        if averageLuminance(img, context) < 0.5 {
            img = img.applyingFilter("CIColorInvert")   // ensure white background
        }
        let crisp = img.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.0,
            kCIInputContrastKey: 9.0,
            kCIInputBrightnessKey: 0.05,
        ])
        let thick = crisp.applyingFilter("CIMorphologyMinimum", parameters: [kCIInputRadiusKey: 1.6])
            .cropped(to: crisp.extent)
        guard let cg = context.createCGImage(thick, from: thick.extent) else { return nil }
        return stretch(UIImage(cgImage: cg), toAspectOf: original, maxDim: 1500)
    }

    private static func averageLuminance(_ image: CIImage, _ context: CIContext) -> CGFloat {
        let avg = image.applyingFilter("CIAreaAverage",
                                       parameters: [kCIInputExtentKey: CIVector(cgRect: image.extent)])
        var px = [UInt8](repeating: 0, count: 4)
        context.render(avg, toBitmap: &px, rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        return (0.299 * CGFloat(px[0]) + 0.587 * CGFloat(px[1]) + 0.114 * CGFloat(px[2])) / 255.0
    }

    private static func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let fmt = UIGraphicsImageRendererFormat.default(); fmt.scale = image.scale
        return UIGraphicsImageRenderer(size: image.size, format: fmt).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private static func stretch(_ image: UIImage, toAspectOf original: UIImage, maxDim: CGFloat) -> UIImage {
        let m = max(original.size.width, original.size.height)
        let f = m > maxDim ? maxDim / m : 1
        let target = CGSize(width: max(1, original.size.width * f), height: max(1, original.size.height * f))
        let fmt = UIGraphicsImageRendererFormat.default(); fmt.scale = 1; fmt.opaque = true
        return UIGraphicsImageRenderer(size: target, format: fmt).image { _ in
            UIColor.white.setFill(); UIRectFill(CGRect(origin: .zero, size: target))
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

/// Produces the colouring outline: uses the on-device AI model when bundled,
/// otherwise the built-in image-processing filter.
enum PhotoOutlineMaker {
    static func make(from image: UIImage) async -> UIImage? {
        if PhotoOutlineAI.isAvailable, let ai = await PhotoOutlineAI.make(from: image) {
            return ai
        }
        return PhotoOutline.make(from: image)
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
            var result: UIImage?
            if let data, let ui = UIImage(data: data) {
                result = await PhotoOutlineMaker.make(from: ui)
            }
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
