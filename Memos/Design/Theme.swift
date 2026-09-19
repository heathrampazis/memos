import SwiftUI

// Chrome colours: the board, the sheets, the controls over them. Neutral by
// design, so the tiles are the only colour on screen and whichever palette is
// chosen has nothing to fight.
//
// Not perfectly grey — a point or two of blue in the light values and the same
// in the dark ones keeps a flat neutral from reading as dirty.
enum Theme {
    static let canvas = Color(hex: 0xF2F2F5)
    static let surface = Color(hex: 0xE6E6EB)
    static let ink = Color(hex: 0x121214)
}
