import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// An image ready to share, used with `.sheet(item:)` so the share sheet only
/// presents once the image actually exists (avoids the blank first-tap sheet).
struct ShareItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Wraps the system share sheet (social media, Messages, AirDrop, Print, Save…).
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// Saves an image to the photo library and reports success/failure.
final class PhotoSaver: NSObject {
    static let shared = PhotoSaver()
    private var completion: ((Bool) -> Void)?

    func save(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        self.completion = completion
        UIImageWriteToSavedPhotosAlbum(image, self,
            #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?,
                             contextInfo: UnsafeRawPointer?) {
        completion?(error == nil)
        completion = nil
    }
}
