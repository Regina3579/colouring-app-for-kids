import SwiftUI

// MARK: - Tools the child can paint with

enum Tool: String, CaseIterable, Identifiable {
    case bucket   // solid paint-bucket fill
    case crayon   // waxy crayon texture
    case glitter  // sparkly glitter fill
    case sparkle  // magic-wand sparkle (same shimmer, wand icon)
    case eraser   // remove the colour again

    var id: String { rawValue }

    /// SF Symbol used in the toolbar.
    var icon: String {
        switch self {
        case .bucket:  return "drop.fill"
        case .crayon:  return "pencil.tip"
        case .glitter: return "sparkles"
        case .sparkle: return "wand.and.stars"
        case .eraser:  return "eraser.fill"
        }
    }

    var title: String {
        switch self {
        case .bucket:  return "Paint"
        case .crayon:  return "Crayon"
        case .glitter: return "Glitter"
        case .sparkle: return "Sparkle"
        case .eraser:  return "Eraser"
        }
    }

    /// Cute emoji shown on the tool button.
    var emoji: String {
        switch self {
        case .bucket:  return "🪣"
        case .crayon:  return "🖍️"
        case .glitter: return "✨"
        case .sparkle: return "🪄"
        case .eraser:  return "🧽"
        }
    }

    /// Glitter and Sparkle are Pro-only tools.
    var isPro: Bool { self == .glitter || self == .sparkle }

    /// True for tools that add sparkles to whatever colour is used.
    var addsSparkle: Bool { self == .glitter || self == .sparkle }
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
    case glitter(Color)
    case fancy(GlitterStyle)

    var colors: [Color] {
        switch self {
        case .solid(let c): return [c]
        case .gradient(let cs): return cs
        case .glitter(let c): return [c]
        case .fancy(let s): return s.base
        }
    }
    var isGradient: Bool {
        if case .gradient = self { return true }
        return false
    }
    /// True for any paint that should render sparkles.
    var sparkles: Bool {
        switch self { case .glitter, .fancy: return true; default: return false }
    }
    /// The special glitter style, if this is a fancy paint.
    var fancyStyle: GlitterStyle? {
        if case .fancy(let s) = self { return s }
        return nil
    }
    /// True for the louder "Sparkle" tab styles — bigger on-canvas sparkles.
    var bigSparkle: Bool {
        if case .fancy(let s) = self { return s.id.hasPrefix("spk_") }
        return false
    }
}

/// A premium glitter: a pearlescent/metallic base plus sparkle colours.
struct GlitterStyle: Equatable {
    let id: String
    let base: [Color]       // soft base the area is filled with
    let sparkle: [Color]    // grain & star sparkle colours
    let intensity: Double   // density multiplier (higher = more shimmer)
}

enum Glitters {
    private static func c(_ r: Double, _ g: Double, _ b: Double) -> Color { Color(red: r, green: g, blue: b) }

    static let holographic = GlitterStyle(
        id: "holo",
        base: [c(1.00, 0.84, 0.94), c(0.86, 0.84, 1.00), c(0.80, 0.96, 1.00),
               c(0.84, 1.00, 0.90), c(1.00, 0.98, 0.80), c(1.00, 0.88, 0.86)],
        sparkle: [c(0.20, 1.00, 0.98), c(1.00, 0.35, 0.88), c(0.62, 0.40, 1.00),
                  c(1.00, 0.85, 0.25), c(0.35, 1.00, 0.60), c(1.00, 0.55, 0.40)],
        intensity: 2.2)

    static let gold = GlitterStyle(
        id: "gold",
        base: [c(1.00, 0.95, 0.74), c(1.00, 0.84, 0.42), c(0.84, 0.64, 0.24)],
        sparkle: [.white, c(1.00, 0.93, 0.58), c(1.00, 0.82, 0.34), c(0.92, 0.68, 0.22)],
        intensity: 1.7)

    static let silver = GlitterStyle(
        id: "silver",
        base: [c(0.98, 0.99, 1.00), c(0.84, 0.88, 0.93), c(0.68, 0.73, 0.80)],
        sparkle: [.white, c(0.90, 0.94, 1.00), c(0.76, 0.81, 0.90), c(0.62, 0.68, 0.78)],
        intensity: 1.7)

    static let unicorn = GlitterStyle(
        id: "unicorn",
        base: [c(1.00, 0.85, 0.93), c(0.90, 0.85, 1.00), c(0.83, 0.95, 1.00),
               c(0.86, 1.00, 0.92), c(1.00, 0.95, 0.84)],
        sparkle: [.white, c(1.00, 0.70, 0.86), c(0.74, 0.64, 1.00), c(1.00, 0.86, 0.46), c(0.55, 0.92, 0.96)],
        intensity: 1.9)

    static let roseGold = GlitterStyle(
        id: "rosegold",
        base: [c(1.00, 0.89, 0.85), c(0.97, 0.74, 0.68), c(0.85, 0.55, 0.50)],
        sparkle: [.white, c(1.00, 0.82, 0.76), c(1.00, 0.88, 0.62), c(0.91, 0.62, 0.56)],
        intensity: 1.8)

    static let galaxy = GlitterStyle(
        id: "galaxy",
        base: [c(0.16, 0.11, 0.34), c(0.34, 0.15, 0.50), c(0.20, 0.18, 0.55), c(0.45, 0.14, 0.44)],
        sparkle: [.white, c(0.55, 0.85, 1.00), c(1.00, 0.55, 0.95), c(1.00, 0.90, 0.55), c(0.78, 0.68, 1.00)],
        intensity: 2.1)

    // MARK: New "Sparkle" tab styles

    static let mermaid = GlitterStyle(
        id: "spk_mermaid",
        base: [c(0.40, 0.92, 0.86), c(0.35, 0.72, 0.95), c(0.55, 0.55, 0.95), c(0.50, 0.88, 0.90)],
        sparkle: [.white, c(0.30, 1.00, 0.95), c(0.55, 0.82, 1.00), c(0.82, 0.70, 1.00)],
        intensity: 2.1)

    static let rainbowSpk = GlitterStyle(
        id: "spk_rainbow",
        base: [c(1.00, 0.45, 0.55), c(1.00, 0.72, 0.35), c(1.00, 0.92, 0.45),
               c(0.50, 0.86, 0.55), c(0.40, 0.66, 1.00), c(0.72, 0.50, 0.95)],
        sparkle: [.white, c(1.00, 0.40, 0.70), c(1.00, 0.90, 0.40), c(0.40, 0.90, 0.60), c(0.50, 0.70, 1.00)],
        intensity: 2.2)

    static let sunsetSpk = GlitterStyle(
        id: "spk_sunset",
        base: [c(1.00, 0.86, 0.45), c(1.00, 0.55, 0.35), c(0.95, 0.35, 0.50), c(0.70, 0.30, 0.55)],
        sparkle: [.white, c(1.00, 0.85, 0.50), c(1.00, 0.60, 0.50), c(1.00, 0.45, 0.60)],
        intensity: 2.0)

    static let aurora = GlitterStyle(
        id: "spk_aurora",
        base: [c(0.35, 0.92, 0.70), c(0.40, 0.70, 0.95), c(0.70, 0.50, 0.95), c(0.95, 0.55, 0.80)],
        sparkle: [.white, c(0.50, 1.00, 0.80), c(0.60, 0.70, 1.00), c(1.00, 0.60, 0.85)],
        intensity: 2.2)

    static let cottonCandy = GlitterStyle(
        id: "spk_cotton",
        base: [c(1.00, 0.80, 0.92), c(0.86, 0.80, 1.00), c(0.80, 0.92, 1.00)],
        sparkle: [.white, c(1.00, 0.75, 0.92), c(0.80, 0.78, 1.00), c(0.70, 0.92, 1.00)],
        intensity: 1.9)

    static let oceanSpk = GlitterStyle(
        id: "spk_ocean",
        base: [c(0.55, 0.92, 0.92), c(0.30, 0.70, 0.92), c(0.20, 0.45, 0.80)],
        sparkle: [.white, c(0.50, 0.95, 1.00), c(0.40, 0.75, 1.00)],
        intensity: 1.9)

    static let bubblegum = GlitterStyle(
        id: "spk_bubblegum",
        base: [c(1.00, 0.55, 0.80), c(1.00, 0.40, 0.65), c(0.85, 0.45, 0.90)],
        sparkle: [.white, c(1.00, 0.60, 0.85), c(0.90, 0.50, 0.95)],
        intensity: 2.0)

    static let lavaSpk = GlitterStyle(
        id: "spk_lava",
        base: [c(1.00, 0.85, 0.30), c(1.00, 0.50, 0.15), c(0.85, 0.20, 0.20)],
        sparkle: [.white, c(1.00, 0.90, 0.40), c(1.00, 0.60, 0.25)],
        intensity: 2.0)

    static let emerald = GlitterStyle(
        id: "spk_emerald",
        base: [c(0.55, 0.95, 0.65), c(0.25, 0.80, 0.55), c(0.15, 0.55, 0.45)],
        sparkle: [.white, c(0.60, 1.00, 0.70), c(0.40, 0.90, 0.60)],
        intensity: 1.9)

    static let peachy = GlitterStyle(
        id: "spk_peach",
        base: [c(1.00, 0.88, 0.72), c(1.00, 0.72, 0.60), c(1.00, 0.60, 0.62)],
        sparkle: [.white, c(1.00, 0.85, 0.65), c(1.00, 0.70, 0.65)],
        intensity: 1.8)

    /// All "Sparkle" tab styles in display order.
    static let sparkleStyles: [GlitterStyle] = [
        mermaid, rainbowSpk, sunsetSpk, aurora, cottonCandy,
        oceanSpk, bubblegum, lavaSpk, emerald, peachy,
    ]
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
    var isPro: Bool = false
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
    /// True if this picture requires Pro to open.
    var isPro: Bool {
        switch self {
        case .vector: return false
        case .image(let p): return p.isPro
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
    /// Optional image asset shown on the category card instead of the emoji.
    var thumbnail: String? = nil
}

// MARK: - A kid friendly colour or gradient the child can pick

struct Swatch: Identifiable, Equatable {
    let id: String
    let paint: Paint
    let name: String
    var isPro: Bool = false
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

    static let glitters: [Swatch] = [
        Swatch(id: "gl_holo",    paint: .fancy(Glitters.holographic), name: "Holographic"),
        Swatch(id: "gl_unicorn", paint: .fancy(Glitters.unicorn),     name: "Unicorn Pastel"),
        Swatch(id: "gl_goldfoil",   paint: .fancy(Glitters.gold),     name: "Gold Foil"),
        Swatch(id: "gl_silverfoil", paint: .fancy(Glitters.silver),   name: "Silver Foil"),
        Swatch(id: "gl_rosegold",   paint: .fancy(Glitters.roseGold), name: "Rose Gold"),
        Swatch(id: "gl_galaxy",     paint: .fancy(Glitters.galaxy),   name: "Galaxy"),
        Swatch(id: "gl_pink",   paint: .glitter(c(1.00, 0.45, 0.75)), name: "Pink Glitter"),
        Swatch(id: "gl_rose",   paint: .glitter(c(0.95, 0.30, 0.45)), name: "Rose Glitter"),
        Swatch(id: "gl_purple", paint: .glitter(c(0.65, 0.40, 0.92)), name: "Purple Glitter"),
        Swatch(id: "gl_blue",   paint: .glitter(c(0.30, 0.50, 0.95)), name: "Blue Glitter"),
        Swatch(id: "gl_sky",    paint: .glitter(c(0.30, 0.75, 0.95)), name: "Sky Glitter"),
        Swatch(id: "gl_teal",   paint: .glitter(c(0.20, 0.78, 0.72)), name: "Teal Glitter"),
        Swatch(id: "gl_green",  paint: .glitter(c(0.40, 0.80, 0.40)), name: "Green Glitter"),
        Swatch(id: "gl_lime",   paint: .glitter(c(0.75, 0.90, 0.30)), name: "Lime Glitter"),
        Swatch(id: "gl_gold",   paint: .glitter(c(1.00, 0.80, 0.25)), name: "Gold Glitter"),
        Swatch(id: "gl_orange", paint: .glitter(c(1.00, 0.55, 0.20)), name: "Orange Glitter"),
        Swatch(id: "gl_red",    paint: .glitter(c(0.95, 0.30, 0.30)), name: "Red Glitter"),
        Swatch(id: "gl_silver", paint: .glitter(c(0.80, 0.82, 0.88)), name: "Silver Glitter"),
    ]

    /// Elegant pastel colours — a Pro palette.
    static let pastels: [Swatch] = [
        Swatch(id: "ps_blush",   paint: .solid(c(1.00, 0.89, 0.89)), name: "Blush", isPro: true),
        Swatch(id: "ps_rose",    paint: .solid(c(0.98, 0.83, 0.85)), name: "Rose Quartz", isPro: true),
        Swatch(id: "ps_petal",   paint: .solid(c(0.99, 0.78, 0.82)), name: "Petal", isPro: true),
        Swatch(id: "ps_peach",   paint: .solid(c(1.00, 0.85, 0.74)), name: "Peach", isPro: true),
        Swatch(id: "ps_apricot", paint: .solid(c(1.00, 0.81, 0.67)), name: "Apricot", isPro: true),
        Swatch(id: "ps_coral",   paint: .solid(c(1.00, 0.77, 0.72)), name: "Soft Coral", isPro: true),
        Swatch(id: "ps_butter",  paint: .solid(c(1.00, 0.94, 0.76)), name: "Butter", isPro: true),
        Swatch(id: "ps_lemon",   paint: .solid(c(0.98, 0.97, 0.80)), name: "Lemon Cream", isPro: true),
        Swatch(id: "ps_vanilla", paint: .solid(c(0.98, 0.95, 0.86)), name: "Vanilla", isPro: true),
        Swatch(id: "ps_honey",   paint: .solid(c(0.90, 0.96, 0.81)), name: "Honeydew", isPro: true),
        Swatch(id: "ps_mint",    paint: .solid(c(0.80, 0.95, 0.84)), name: "Mint", isPro: true),
        Swatch(id: "ps_seafoam", paint: .solid(c(0.76, 0.94, 0.88)), name: "Seafoam", isPro: true),
        Swatch(id: "ps_aqua",    paint: .solid(c(0.78, 0.93, 0.94)), name: "Aqua Mist", isPro: true),
        Swatch(id: "ps_sky",     paint: .solid(c(0.80, 0.91, 0.99)), name: "Baby Sky", isPro: true),
        Swatch(id: "ps_powder",  paint: .solid(c(0.84, 0.89, 0.98)), name: "Powder Blue", isPro: true),
        Swatch(id: "ps_peri",    paint: .solid(c(0.81, 0.83, 0.98)), name: "Periwinkle", isPro: true),
        Swatch(id: "ps_lavender",paint: .solid(c(0.88, 0.83, 0.98)), name: "Lavender", isPro: true),
        Swatch(id: "ps_lilac",   paint: .solid(c(0.91, 0.81, 0.96)), name: "Lilac", isPro: true),
        Swatch(id: "ps_wisteria",paint: .solid(c(0.85, 0.79, 0.93)), name: "Wisteria", isPro: true),
        Swatch(id: "ps_mauve",   paint: .solid(c(0.91, 0.81, 0.88)), name: "Mauve", isPro: true),
        Swatch(id: "ps_rosewater",paint: .solid(c(0.98, 0.88, 0.92)), name: "Rosewater", isPro: true),
        Swatch(id: "ps_sage",    paint: .solid(c(0.83, 0.89, 0.79)), name: "Sage", isPro: true),
        Swatch(id: "ps_greige",  paint: .solid(c(0.90, 0.88, 0.83)), name: "Greige", isPro: true),
        Swatch(id: "ps_cloud",   paint: .solid(c(0.91, 0.93, 0.97)), name: "Cloud", isPro: true),
    ]

    // Glitter swatches are Pro-only too.
    static let swatches: [Swatch] = solids + pastels + gradients
        + glitters.map { Swatch(id: $0.id, paint: $0.paint, name: $0.name, isPro: true) }

    /// New "Sparkle" tab — extra glittery styles (separate from Glitter).
    static let sparkles: [Swatch] = [
        Swatch(id: "spk_mermaid",   paint: .fancy(Glitters.mermaid),     name: "Mermaid"),
        Swatch(id: "spk_rainbow",   paint: .fancy(Glitters.rainbowSpk),  name: "Rainbow"),
        Swatch(id: "spk_sunset",    paint: .fancy(Glitters.sunsetSpk),   name: "Sunset"),
        Swatch(id: "spk_aurora",    paint: .fancy(Glitters.aurora),      name: "Aurora"),
        Swatch(id: "spk_cotton",    paint: .fancy(Glitters.cottonCandy), name: "Cotton Candy"),
        Swatch(id: "spk_ocean",     paint: .fancy(Glitters.oceanSpk),    name: "Ocean"),
        Swatch(id: "spk_bubblegum", paint: .fancy(Glitters.bubblegum),   name: "Bubblegum"),
        Swatch(id: "spk_lava",      paint: .fancy(Glitters.lavaSpk),     name: "Lava"),
        Swatch(id: "spk_emerald",   paint: .fancy(Glitters.emerald),     name: "Emerald"),
        Swatch(id: "spk_peach",     paint: .fancy(Glitters.peachy),      name: "Peachy"),
    ]

    static var defaultPaint: Paint { solids[1].paint }
    static var defaultID: String { solids[1].id }

    /// Frees the swatches with the given ids (shown first), locking the rest as
    /// Pro — so kids can try a couple of clearly different colours before
    /// unlocking everything.
    static func freeFirst(_ freeIDs: [String], _ swatches: [Swatch]) -> [Swatch] {
        let free = freeIDs.compactMap { id in swatches.first { $0.id == id } }
            .map { Swatch(id: $0.id, paint: $0.paint, name: $0.name, isPro: false) }
        let rest = swatches.filter { !freeIDs.contains($0.id) }
            .map { Swatch(id: $0.id, paint: $0.paint, name: $0.name, isPro: true) }
        return free + rest
    }
}

// MARK: - Palette groups shown behind tappable category buttons

/// Splits the long colour list into tidy tabs so kids tap a group
/// (e.g. "Pastel") to reveal just those colours.
enum PaletteCategory: String, CaseIterable, Identifiable {
    case colours, pastel, fade, glitter, sparkle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .colours: return "Colours"
        case .pastel:  return "Pastel"
        case .fade:    return "Fade"
        case .glitter: return "Glitter"
        case .sparkle: return "Sparkle"
        }
    }

    var emoji: String {
        switch self {
        case .colours: return "🎨"
        case .pastel:  return "🌸"
        case .fade:    return "🌈"
        case .glitter: return "✨"
        case .sparkle: return "🪄"
        }
    }

    /// The swatches shown when this tab is selected.
    var swatches: [Swatch] {
        switch self {
        case .colours: return Palette.solids
        case .pastel:  return Palette.freeFirst(["ps_blush", "ps_sky"], Palette.pastels)
        case .fade:    return Palette.gradients
        case .glitter: return Palette.freeFirst(["gl_holo", "gl_goldfoil"], Palette.glitters)
        case .sparkle: return Palette.freeFirst(["spk_mermaid", "spk_rainbow"], Palette.sparkles)
        }
    }

    /// True if the whole group is Pro-only (shows a crown on the tab).
    var isPro: Bool { self == .pastel || self == .glitter || self == .sparkle }
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
