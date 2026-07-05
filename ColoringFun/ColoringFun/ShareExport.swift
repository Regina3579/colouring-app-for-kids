import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import Photos

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
///
/// Uses the modern Photos framework (no Objective-C selector callback), which
/// avoids the "unrecognized selector" abort the old
/// `UIImageWriteToSavedPhotosAlbum(_:_:_:_:)` API could trigger.
final class PhotoSaver {
    static let shared = PhotoSaver()

    func save(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        func finish(_ ok: Bool) { DispatchQueue.main.async { completion(ok) } }

        func write() {
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                finish(success)
            }
        }

        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            write()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                if status == .authorized || status == .limited { write() }
                else { finish(false) }
            }
        default:
            finish(false)   // denied / restricted
        }
    }
}

