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

    /// Saves a finished picture (and optionally its editable state); returns success.
    @discardableResult
    func save(_ image: UIImage, state: DrawingState? = nil) -> Bool {
        guard let data = image.pngData() else { return false }
        let base = "drawing-\(Int(Date().timeIntervalSince1970 * 1000))"
        do {
            try data.write(to: folder.appendingPathComponent(base + ".png"))
            if let state, let json = try? JSONEncoder().encode(state) {
                try? json.write(to: folder.appendingPathComponent(base + ".json"))
            }
            reload()
            return true
        } catch {
            return false
        }
    }

    func image(_ drawing: SavedDrawing) -> UIImage? {
        UIImage(contentsOfFile: drawing.url.path)
    }

    /// The saved editable state for a drawing, if any.
    func state(_ drawing: SavedDrawing) -> DrawingState? {
        let jsonURL = drawing.url.deletingPathExtension().appendingPathExtension("json")
        guard let data = try? Data(contentsOf: jsonURL) else { return nil }
        return try? JSONDecoder().decode(DrawingState.self, from: data)
    }

    func delete(_ drawing: SavedDrawing) {
        try? FileManager.default.removeItem(at: drawing.url)
        let jsonURL = drawing.url.deletingPathExtension().appendingPathExtension("json")
        try? FileManager.default.removeItem(at: jsonURL)
        reload()
    }
}
