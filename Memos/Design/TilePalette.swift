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
    private static let names = ["Base", "Yellow", "Orange", "Rose", "Green", "Blue", "Violet"]

    static func colors(for kind: TilePaletteKind) -> [TileColor] {
        fills(for: kind).enumerated().map { index, hex in
            build(index, names[index], hex)
        }
    }

    static func color(_ index: Int, in kind: TilePaletteKind) -> TileColor {
        let all = colors(for: kind)
        return all.indices.contains(index) ? all[index] : all[0]
    }

    // Every fill stays light enough to carry ink text.
    private static func fills(for kind: TilePaletteKind) -> [UInt32] {
        switch kind {
        case .colour:
            [0xFFFFFF, 0xFFD12E, 0xFF9F43, 0xFF8FA8, 0x46D89C, 0x4FBDF7, 0xB69EFF]
        case .paper:
            [0xFFFDF7, 0xFAF5EA, 0xF3EBDB, 0xEBE1CD, 0xE3D7BE, 0xDACCAF, 0xD1C1A1]
        case .slate:
            [0xFFFFFF, 0xF6F9FC, 0xEBF1F7, 0xDFE7F0, 0xD3DDE8, 0xC6D2E0, 0xB9C7D8]
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
