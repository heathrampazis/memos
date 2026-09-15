import SwiftUI

struct TileColor: Identifiable, Hashable {
    let id: Int
    let name: String
    let fill: Color
    /// The hard offset under a tile.
    let shadow: Color
    /// Trays and sheets sitting over the tile: a step darker than the page, so
    /// they read as chrome without bringing in a colour from somewhere else.
    let tray: Color
    /// Only the white tile needs an outline; the coloured ones separate
    /// themselves from the canvas.
    let edge: Color?
}

enum TilePalette {
    static let all: [TileColor] = [
        TileColor(id: 0, name: "Paper",  fill: Color(hex: 0xFFFFFF), shadow: Color(hex: 0xE2DBCB), tray: Color(hex: 0xF4EFE6), edge: Theme.cardEdge),
        TileColor(id: 1, name: "Yellow", fill: Color(hex: 0xFFD12E), shadow: Color(hex: 0xE0B828), tray: Color(hex: 0xEDC12A), edge: nil),
        TileColor(id: 2, name: "Orange", fill: Color(hex: 0xFF9F43), shadow: Color(hex: 0xE08C3B), tray: Color(hex: 0xED933E), edge: nil),
        TileColor(id: 3, name: "Rose",   fill: Color(hex: 0xFF8FA8), shadow: Color(hex: 0xE07E94), tray: Color(hex: 0xED849B), edge: nil),
        TileColor(id: 4, name: "Green",  fill: Color(hex: 0x46D89C), shadow: Color(hex: 0x3EBE89), tray: Color(hex: 0x41C790), edge: nil),
        TileColor(id: 5, name: "Blue",   fill: Color(hex: 0x4FBDF7), shadow: Color(hex: 0x46A6D9), tray: Color(hex: 0x49AEE4), edge: nil),
        TileColor(id: 6, name: "Violet", fill: Color(hex: 0xB69EFF), shadow: Color(hex: 0xA08BE0), tray: Color(hex: 0xA892EB), edge: nil),
    ]

    static func color(_ index: Int) -> TileColor {
        all.indices.contains(index) ? all[index] : all[0]
    }
}

/// Text sitting on a tile. Ink at reduced opacity rather than a fixed grey, so
/// it settles into whatever colour the tile is instead of fighting it.
enum TileInk {
    static let primary = Theme.ink
    static let secondary = Theme.ink.opacity(0.70)
    static let tertiary = Theme.ink.opacity(0.45)
    static let faint = Theme.ink.opacity(0.32)
}
