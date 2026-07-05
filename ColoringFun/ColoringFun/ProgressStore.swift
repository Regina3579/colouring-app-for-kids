import SwiftUI

/// Auto-saves each picture's in-progress colouring (per page id) so leaving
/// and returning keeps the work exactly as it was.
final class ProgressStore {
    static let shared = ProgressStore()
    private let folder: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        folder = docs.appendingPathComponent("Progress", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    private func url(_ pageID: String) -> URL {
        let safe = pageID.replacingOccurrences(of: "/", with: "_")
        return folder.appendingPathComponent(safe + ".json")
    }

    func save(pageID: String, state: DrawingState) {
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: url(pageID))
        }
    }

    func load(pageID: String) -> DrawingState? {
        guard let data = try? Data(contentsOf: url(pageID)) else { return nil }
        return try? JSONDecoder().decode(DrawingState.self, from: data)
    }

    func clear(pageID: String) {
        try? FileManager.default.removeItem(at: url(pageID))
    }
}
