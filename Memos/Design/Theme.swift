import SwiftUI

/// Chrome colours. These are fixed rather than appearance-aware on purpose:
/// dark mode darkens the board behind the tiles, it does not invert the panels
/// over them. Anything that does change with appearance lives on AppSettings.
enum Theme {
    static let canvas = Color(hex: 0xF1EDE4)
    static let card = Color(hex: 0xFFFFFF)
    static let cardEdge = Color(hex: 0xEDE8DC)

    static let surface = Color(hex: 0xE9E3D7)
    static let border = Color(hex: 0xDED7C8)

    static let ink = Color(hex: 0x17120E)
    static let muted = Color(hex: 0x7C736A)
    static let faint = Color(hex: 0xA79E93)

    /// Warm rather than black. A neutral shadow on a cream ground goes grey
    /// and reads as dirt instead of depth.
    static let shadowTint = Color(hex: 0x2B1F12)
}
