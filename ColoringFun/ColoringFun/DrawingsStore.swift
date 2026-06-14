import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// One finished drawing saved inside the app.
struct SavedDrawing: Identifiable {
    let id: String      // file name
    let url: URL
    let date: Date
}

/// Stores the child's finished drawings in the app's "MyDrawings" folder.
final class DrawingsStore: ObservableObject {
    static let shared = DrawingsStore()

    @Published private(set) var drawings: [SavedDrawing] = []
    private let folder: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        folder = docs.appendingPathComponent("MyDrawings", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        reload()
    }

    func reload() {
        let fm = FileManager.default
        let files = (try? fm.contentsOfDirectory(at: folder,
                                                 includingPropertiesForKeys: [.creationDateKey])) ?? []
        drawings = files
            .filter { $0.pathExtension.lowercased() == "png" }
            .map { url in
                let date = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return SavedDrawing(id: url.lastPathComponent, url: url, date: date)
            }
            .sorted { $0.date > $1.date }
    }

    /// Saves a finished picture; returns success.
    @discardableResult
    func save(_ image: UIImage) -> Bool {
        guard let data = image.pngData() else { return false }
        let name = "drawing-\(Int(Date().timeIntervalSince1970)).png"
        do {
            try data.write(to: folder.appendingPathComponent(name))
            reload()
            return true
        } catch {
            return false
        }
    }

    func image(_ drawing: SavedDrawing) -> UIImage? {
        UIImage(contentsOfFile: drawing.url.path)
    }

    func delete(_ drawing: SavedDrawing) {
        try? FileManager.default.removeItem(at: drawing.url)
        reload()
    }
}
