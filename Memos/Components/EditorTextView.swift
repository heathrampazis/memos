import Foundation
import UIKit

/// The text view used for one run of a note. Two things it needs that a plain
/// UITextView won't do: tell the editor when backspace runs off the top of the
/// run, and keep the caret in view now that the page scrolls rather than it.
final class EditorTextView: UITextView {
    /// Returns true when the editor consumed the press — joined this run onto
    /// the one above, or removed the widget between them.
    var onDeleteBackwardAtStart: (() -> Bool)?

    override func deleteBackward() {
        if selectedRange.location == 0,
           selectedRange.length == 0,
           onDeleteBackwardAtStart?() == true {
            return
        }
        super.deleteBackward()
    }

    func revealCaret() {
        guard let range = selectedTextRange else { return }
        let caret = caretRect(for: range.end)
        guard caret.isFinite, !caret.isNull else { return }

        let target = caret.insetBy(dx: 0, dy: -10)
        var candidate: UIView? = superview
        while let view = candidate {
            if let scroll = view as? UIScrollView {
                scroll.scrollRectToVisible(convert(target, to: scroll), animated: true)
                return
            }
            candidate = view.superview
        }
    }
}

private extension CGRect {
    var isFinite: Bool {
        origin.x.isFinite && origin.y.isFinite && size.width.isFinite && size.height.isFinite
    }
}
