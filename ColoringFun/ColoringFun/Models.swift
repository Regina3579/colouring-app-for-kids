import SwiftUI

// MARK: - Tools the child can paint with

enum Tool: String, CaseIterable, Identifiable {
    case bucket   // solid paint-bucket fill
    case crayon   // waxy crayon texture
    case glitter  // sparkly glitter fill
    case eraser   // remove the colour again

    var id: String { rawValue }

    /// SF Symbol used in the toolbar.
    var icon: String {
        switch self {
        case .bucket:  return "drop.fill"
        case .crayon:  return "pencil.tip"
        case .glitter: return "sparkles"
        case .eraser:  return "eraser.fill"
        }
    }

    var title: String {
        switch self {
        case .bucket:  return "Paint"
        case .crayon:  return "Crayon"
        case .glitter: return "Glitter"
        case .eraser:  return "Eraser"
        }
    }
}

// MARK: - A single fillable part of a picture

struct Region: Identifiable {
    let id: Int
    /// Path is described in the page's design coordinate space.
    let path: Path
}

// MARK: - What a child painted into one region

struct Fill: Equatable {
    var color: Color
    var tool: Tool
}

// MARK: - A complete colouring picture

struct ColoringPage: Identifiable {
    let id: String
    let title: String
    let emoji: String
    /// Design canvas size; regions are defined inside this rectangle.
    let canvas: CGSize
    /// Back-to-front ordered fillable regions.
    let regions: [Region]
    /// Optional thin details (whiskers, smiles…) drawn on top, not fillable.
    var decorations: Path? = nil
    /// Soft pastel colour shown behind the picture in the gallery card.
    let cardTint: Color
}

// MARK: - A kid friendly colour the child can pick

struct Swatch: Identifiable, Equatable {
    let id = UUID()
    let color: Color
    let name: String
}

enum Palette {
    static let swatches: [Swatch] = [
        Swatch(color: Color(red: 0.98, green: 0.25, blue: 0.30), name: "Red"),
        Swatch(color: Color(red: 1.00, green: 0.55, blue: 0.20), name: "Orange"),
        Swatch(color: Color(red: 1.00, green: 0.82, blue: 0.22), name: "Yellow"),
        Swatch(color: Color(red: 0.45, green: 0.80, blue: 0.32), name: "Green"),
        Swatch(color: Color(red: 0.25, green: 0.72, blue: 0.85), name: "Sky"),
        Swatch(color: Color(red: 0.27, green: 0.45, blue: 0.92), name: "Blue"),
        Swatch(color: Color(red: 0.62, green: 0.38, blue: 0.86), name: "Purple"),
        Swatch(color: Color(red: 1.00, green: 0.58, blue: 0.78), name: "Pink"),
        Swatch(color: Color(red: 0.60, green: 0.40, blue: 0.25), name: "Brown"),
        Swatch(color: Color(red: 0.20, green: 0.22, blue: 0.28), name: "Black"),
        Swatch(color: Color(red: 0.96, green: 0.96, blue: 0.98), name: "White"),
        Swatch(color: Color(red: 0.78, green: 0.82, blue: 0.86), name: "Grey"),
    ]
}

// MARK: - Deterministic randomness so glitter does not flicker on redraw

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
    /// Uniform Double in [0, 1).
    mutating func unit() -> Double { Double(next() >> 11) * (1.0 / 9007199254740992.0) }
}
