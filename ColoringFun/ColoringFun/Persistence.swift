import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Colour <-> components

extension Color {
    var rgbaComponents: [Double] {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [Double(r), Double(g), Double(b), Double(a)]
        #else
        return [0, 0, 0, 1]
        #endif
    }
    init(components c: [Double]) {
        let v = c.count == 4 ? c : [0, 0, 0, 1]
        self = Color(.sRGB, red: v[0], green: v[1], blue: v[2], opacity: v[3])
    }
}

extension Glitters {
    static func byID(_ id: String) -> GlitterStyle? {
        [holographic, gold, silver, unicorn, roseGold, galaxy].first { $0.id == id }
    }
}

// MARK: - Codable representations of the editable state

struct PaintDTO: Codable {
    var type: String           // solid | gradient | glitter | fancy
    var colors: [[Double]]?    // solid/glitter: 1 colour, gradient: many
    var styleID: String?       // fancy glitter style id

    init(_ paint: Paint) {
        switch paint {
        case .solid(let c):    type = "solid";    colors = [c.rgbaComponents]
        case .glitter(let c):  type = "glitter";  colors = [c.rgbaComponents]
        case .gradient(let cs): type = "gradient"; colors = cs.map { $0.rgbaComponents }
        case .fancy(let s):    type = "fancy";    styleID = s.id
        }
    }

    var paint: Paint {
        switch type {
        case "gradient": return .gradient((colors ?? []).map { Color(components: $0) })
        case "glitter":  return .glitter(Color(components: colors?.first ?? [0, 0, 0, 1]))
        case "fancy":    return .fancy(Glitters.byID(styleID ?? "") ?? Glitters.holographic)
        default:         return .solid(Color(components: colors?.first ?? [0, 0, 0, 1]))
        }
    }
}

struct FillDTO: Codable {
    var id: Int
    var paint: PaintDTO
    var tool: String
}

struct OpDTO: Codable {
    var x: Double
    var y: Double
    var paint: PaintDTO
    var tool: String
}

/// The saved, re-openable state of one drawing.
struct DrawingState: Codable {
    var pageID: String
    var kind: String              // "vector" | "image"
    var fills: [FillDTO]?         // vector pages
    var ops: [OpDTO]?             // image pages

    /// Vector fills as a dictionary.
    func fillsDict() -> [Int: Fill] {
        var out: [Int: Fill] = [:]
        for f in fills ?? [] {
            out[f.id] = Fill(paint: f.paint.paint, tool: Tool(rawValue: f.tool) ?? .bucket)
        }
        return out
    }

    /// Image ops converted to the flood-fill model's Op type.
    func floodOps() -> [FloodFillModel.Op] {
        (ops ?? []).map {
            FloodFillModel.Op(point: CGPoint(x: $0.x, y: $0.y),
                              paint: $0.paint.paint,
                              tool: Tool(rawValue: $0.tool) ?? .bucket)
        }
    }

    static func vector(pageID: String, fills: [Int: Fill]) -> DrawingState {
        DrawingState(pageID: pageID, kind: "vector",
                     fills: fills.map { FillDTO(id: $0.key, paint: PaintDTO($0.value.paint),
                                                tool: $0.value.tool.rawValue) },
                     ops: nil)
    }

    static func image(pageID: String, ops: [FloodFillModel.Op]) -> DrawingState {
        DrawingState(pageID: pageID, kind: "image", fills: nil,
                     ops: ops.map { OpDTO(x: Double($0.point.x), y: Double($0.point.y),
                                          paint: PaintDTO($0.paint), tool: $0.tool.rawValue) })
    }
}

// MARK: - Look up a page by id (for re-opening a saved drawing)

extension Categories {
    static func item(forID id: String) -> CategoryItem? {
        for category in all {
            for item in category.items where item.id == id { return item }
        }
        return nil
    }
}
