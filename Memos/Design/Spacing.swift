import Foundation
import SwiftUI

// Layout constants.
enum Spacing {
    static let screen: CGFloat = 20
    static let gridGap: CGFloat = 13
    static let cardRadius: CGFloat = 20
    static let cardPadding: CGFloat = 15
    static let cardShadowOffset: CGFloat = 3
    // Clearance between the last row of tiles and the home indicator.
    static let homeBottomInset: CGFloat = 56

    // List marker column.
    static let listMarkerWidth: CGFloat = 20
    static let listMarkerGap: CGFloat = 8
    static let listIndent: CGFloat = 28

    // A quote's rule sits in the gutter before its text.
    static let quoteIndent: CGFloat = 18
    static let quoteRuleWidth: CGFloat = 3

    // Breathing room under the last line.
    static let editorTrailingSpace: CGFloat = 24

    // A run of text between two widgets can be empty and still has to be tappable, so it never
    // collapses below one line.
    static let minimumTextRun: CGFloat = 26

    // The editing tray's top corners.
    static let circleButton: CGFloat = 44

    // Inside a 44pt navigation bar a 44pt circle has no margin left, and from iOS 26 the
    // system squeezes it to fit its own toolbar metrics. Bar buttons get their own size.
    static let toolbarCircleButton: CGFloat = 36
    static let addWidgetButton: CGFloat = 54
    static let widgetOptionButton: CGFloat = 46

    // Empty room under the last run, tappable so the caret goes to the end of the note the way
    // it does in Notes.
    static let editorTailTap: CGFloat = 130

    // Kept clear beneath the caret while typing, so a line never ends up under
    // the floating (+).
    static let caretClearance: CGFloat = addWidgetButton + 28

    static let trayRadius: CGFloat = 22

    // How far the tray's fill runs past the bottom of the screen, so its square lower edge and
    // border never come into view.
    static let trayBleed: CGFloat = 90
}
