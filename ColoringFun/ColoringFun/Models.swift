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

// MARK: - What a child paints with: a solid colour or a gradient blend

enum Paint: Equatable {
    case solid(Color)
    case gradient([Color])

    var colors: [Color] {
        switch self {
        case .solid(let c): return [c]
        case .gradient(let cs): return cs
        }
    }
    var isGradient: Bool {
        if case .gradient = self { return true }
        return false
    }
}

// MARK: - What a child painted into one region

struct Fill: Equatable {
    var paint: Paint
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

// MARK: - A picture backed by a real outline image (tap-to-flood-fill)

struct ImagePage: Identifiable {
    let id: String
    let title: String
    let emoji: String
    let imageName: String
    let cardTint: Color
}

// MARK: - An item in a category: either a vector picture or an image picture

enum CategoryItem: Identifiable {
    case vector(ColoringPage)
    case image(ImagePage)

    var id: String {
        switch self {
        case .vector(let p): return p.id
        case .image(let p): return p.id
        }
    }
    var title: String {
        switch self {
        case .vector(let p): return p.title
        case .image(let p): return p.title
        }
    }
    var emoji: String {
        switch self {
        case .vector(let p): return p.emoji
        case .image(let p): return p.emoji
        }
    }
}

// MARK: - A themed section holding many pictures

struct Category: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let tint: Color
    let items: [CategoryItem]
}

// MARK: - A kid friendly colour or gradient the child can pick

struct Swatch: Identifiable, Equatable {
    let id: String
    let paint: Paint
    let name: String
}

enum Palette {
    private static func c(_ r: Double, _ g: Double, _ b: Double) -> Color {
        Color(red: r, green: g, blue: b)
    }

    static let solids: [Swatch] = [
        Swatch(id: "red",    paint: .solid(c(0.98, 0.25, 0.30)), name: "Red"),
        Swatch(id: "orange", paint: .solid(c(1.00, 0.55, 0.20)), name: "Orange"),
        Swatch(id: "yellow", paint: .solid(c(1.00, 0.82, 0.22)), name: "Yellow"),
        Swatch(id: "green",  paint: .solid(c(0.45, 0.80, 0.32)), name: "Green"),
        Swatch(id: "sky",    paint: .solid(c(0.25, 0.72, 0.85)), name: "Sky"),
        Swatch(id: "blue",   paint: .solid(c(0.27, 0.45, 0.92)), name: "Blue"),
        Swatch(id: "purple", paint: .solid(c(0.62, 0.38, 0.86)), name: "Purple"),
        Swatch(id: "pink",   paint: .solid(c(1.00, 0.58, 0.78)), name: "Pink"),
        Swatch(id: "brown",  paint: .solid(c(0.60, 0.40, 0.25)), name: "Brown"),
        Swatch(id: "black",  paint: .solid(c(0.20, 0.22, 0.28)), name: "Black"),
        Swatch(id: "white",  paint: .solid(c(0.96, 0.96, 0.98)), name: "White"),
        Swatch(id: "grey",   paint: .solid(c(0.78, 0.82, 0.86)), name: "Grey"),
    ]

    static let gradients: [Swatch] = [
        Swatch(id: "rainbow",
               paint: .gradient([c(0.98, 0.25, 0.30), c(1.00, 0.60, 0.20), c(1.00, 0.85, 0.25),
                                 c(0.40, 0.80, 0.35), c(0.25, 0.55, 0.95), c(0.62, 0.38, 0.86)]),
               name: "Rainbow"),
        Swatch(id: "sunset",
               paint: .gradient([c(1.00, 0.85, 0.35), c(1.00, 0.50, 0.35), c(0.85, 0.25, 0.55)]),
               name: "Sunset"),
        Swatch(id: "ocean",
               paint: .gradient([c(0.55, 0.95, 0.90), c(0.20, 0.65, 0.90), c(0.20, 0.35, 0.75)]),
               name: "Ocean"),
        Swatch(id: "candy",
               paint: .gradient([c(1.00, 0.70, 0.85), c(0.80, 0.45, 0.90), c(0.55, 0.55, 0.95)]),
               name: "Candy"),
        Swatch(id: "fire",
               paint: .gradient([c(1.00, 0.90, 0.30), c(1.00, 0.55, 0.15), c(0.90, 0.20, 0.20)]),
               name: "Fire"),
        Swatch(id: "lime",
               paint: .gradient([c(0.85, 0.95, 0.35), c(0.45, 0.80, 0.35), c(0.15, 0.60, 0.45)]),
               name: "Lime"),
        Swatch(id: "berry",
               paint: .gradient([c(1.00, 0.55, 0.75), c(0.90, 0.25, 0.45), c(0.55, 0.20, 0.55)]),
               name: "Berry"),
        Swatch(id: "grape",
               paint: .gradient([c(0.70, 0.55, 0.95), c(0.50, 0.35, 0.85), c(0.30, 0.25, 0.65)]),
               name: "Grape"),
        Swatch(id: "mermaid",
               paint: .gradient([c(0.40, 0.95, 0.80), c(0.35, 0.70, 0.90), c(0.65, 0.45, 0.95)]),
               name: "Mermaid"),
        Swatch(id: "peach",
               paint: .gradient([c(1.00, 0.92, 0.75), c(1.00, 0.72, 0.55), c(1.00, 0.55, 0.55)]),
               name: "Peach"),
    ]

    static let swatches: [Swatch] = solids + gradients

    static var defaultPaint: Paint { solids[1].paint }
    static var defaultID: String { solids[1].id }
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
