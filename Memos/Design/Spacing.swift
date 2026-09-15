import Foundation
import SwiftUI

/// Layout constants. No magic numbers in views.
enum Spacing {
    static let screen: CGFloat = 20
    static let gridGap: CGFloat = 13
    static let cardRadius: CGFloat = 20
    static let cardPadding: CGFloat = 15
    static let cardShadowOffset: CGFloat = 3
    /// Clearance between the last row of tiles and the home indicator.
    static let homeBottomInset: CGFloat = 56

    /// List marker column. Nudge the gap if bullets sit off the text.
    static let listMarkerWidth: CGFloat = 20
    static let listMarkerGap: CGFloat = 8

    /// Breathing room under the last line. Keep this small: a large bottom
    /// inset gives the text view empty space to scroll into, which lets it
    /// push the caret to the top of the screen instead of keeping it low.
    static let editorTrailingSpace: CGFloat = 24

    /// The editing tray's top corners.
    static let circleButton: CGFloat = 44

    static let trayRadius: CGFloat = 22

    /// How far the tray's fill runs past the bottom of the screen, so its
    /// square lower edge and border never come into view.
    static let trayBleed: CGFloat = 90
}
