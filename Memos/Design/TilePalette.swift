import SwiftUI

enum TilePaletteKind: String, CaseIterable, Identifiable, Codable {
    case colour, paper, slate

    var id: String { rawValue }

    var label: String {
        switch self {
        case .colour: "Colour"
        case .paper: "Paper"
        case .slate: "Slate"
        }
    }

    var caption: String {
        switch self {
        case .colour: "Highlighter brights"
        case .paper: "Warm neutrals"
        case .slate: "Cool greys"
        }
    }
}

struct TileColor: Identifiable, Hashable {
    let id: Int
    let name: String
    let fill: Color
    // The delete badge and other pressed-in surfaces.
    let shadow: Color
    // Trays and sheets over the tile: a step away from the page so they read as chrome without
    // bringing in a colour from somewhere else.
    let tray: Color
    let edge: Color
    // Text on this tile.
    let ink: Color

    var inkSecondary: Color { ink.opacity(0.74) }
    var inkTertiary: Color { ink.opacity(0.55) }
    var inkFaint: Color { ink.opacity(0.42) }
}

enum TilePalettes {
    static func colors(for kind: TilePaletteKind) -> [TileColor] {
        swatches(for: kind).enumerated().map { index, swatch in
            build(index, swatch.name, swatch.fill)
        }
    }

    static func color(_ index: Int, in kind: TilePaletteKind) -> TileColor {
        let all = colors(for: kind)
        return all.indices.contains(index) ? all[index] : all[0]
    }

    // Names travel with their fills. Held apart, one list of names served all
    // three palettes and a page of warm neutrals was still calling itself rose
    // and violet. Every fill stays light enough to carry ink text.
    private static func swatches(for kind: TilePaletteKind) -> [(name: String, fill: UInt32)] {
        switch kind {
        case .colour:
            [
                ("Base", 0xFFFFFF), ("Yellow", 0xFFD12E), ("Orange", 0xFF9F43),
                ("Rose", 0xFF8FA8), ("Green", 0x46D89C), ("Blue", 0x4FBDF7),
                ("Violet", 0xB69EFF),
            ]
        case .paper:
            [
                ("Base", 0xFFFDF7), ("Ivory", 0xFAF5EA), ("Cream", 0xF3EBDB),
                ("Manila", 0xEBE1CD), ("Oat", 0xE3D7BE), ("Sand", 0xDACCAF),
                ("Kraft", 0xD1C1A1),
            ]
        case .slate:
            [
                ("Base", 0xFFFFFF), ("Mist", 0xF6F9FC), ("Frost", 0xEBF1F7),
                ("Ash", 0xDFE7F0), ("Pewter", 0xD3DDE8), ("Steel", 0xC6D2E0),
                ("Denim", 0xB9C7D8),
            ]
        }
    }

    private static func build(_ id: Int, _ name: String, _ hex: UInt32) -> TileColor {
        TileColor(
            id: id,
            name: name,
            fill: Color(hex: hex),
            shadow: Color(hex: scaled(hex, 0.88)),
            tray: Color(hex: scaled(hex, 0.93)),
            edge: Color(hex: scaled(hex, 0.94)),
            ink: Color(hex: 0x17120E)
        )
    }

    private static func scaled(_ hex: UInt32, _ k: Double) -> UInt32 {
        let channel = { (shift: UInt32) -> UInt32 in
            let value = Double((hex >> shift) & 0xFF) * k
            return UInt32(max(0, min(255, value.rounded())))
        }
        return (channel(16) << 16) | (channel(8) << 8) | channel(0)
    }
}
