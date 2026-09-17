import Foundation
import SwiftUI
import UIKit

/// Owns the text view and every edit made to it. The format bar talks to this
/// rather than to the text, so styling runs through UIKit where the caret,
/// selection and typing attributes already live.
@Observable
final class RichTextController {
    weak var textView: UITextView?

    /// Text colour for the tile this editor is showing.
    var inkColor: UIColor = UIColor(Theme.ink)

    private(set) var level: TextLevel = .body
    private(set) var isBold = false
    private(set) var isItalic = false
    private(set) var isUnderlined = false
    private(set) var isEditing = false

    /// Which run of the note holds the caret. The note is several text views
    /// now, so "the text view" is whichever one is being typed in.
    private(set) var activeID: UUID?

    /// Asks a particular run to take the caret. Set by the editor after it
    /// splits or joins runs; the run itself clears it once it has obeyed.
    var focusRequest: FocusRequest?

    struct FocusRequest: Equatable {
        let segmentID: UUID
        let location: Int
    }

    /// While we are rewriting attributes ourselves, the caret moves and UIKit
    /// reports changes we would otherwise read back and undo.
    private var isStyling = false

    // MARK: Reading the caret

    func syncState() {
        guard let textView, !isStyling else { return }
        isEditing = textView.isFirstResponder

        let attributes = attributesAtCaret(in: textView)
        level = RichText.level(in: attributes)
        isBold = RichText.isBold(in: attributes)
        isItalic = RichText.isItalic(in: attributes)
        isUnderlined = RichText.isUnderlined(in: attributes)

        // Put the full set back. UIKit rebuilds typingAttributes from nearby
        // text whenever the caret moves and does not carry custom keys across,
        // so without this the level is lost the moment you move.
        textView.typingAttributes = RichText.attributes(
            level: level, bold: isBold, italic: isItalic, underlined: isUnderlined, ink: inkColor
        )
    }

    /// The text is the source of truth, not typingAttributes. The character
    /// behind the caret is what the next one will look like.
    private func attributesAtCaret(in textView: UITextView) -> [NSAttributedString.Key: Any] {
        let text = textView.attributedText ?? NSAttributedString()
        let range = textView.selectedRange

        if range.length > 0, range.location < text.length {
            return text.attributes(at: range.location, effectiveRange: nil)
        }
        if range.location > 0, range.location <= text.length {
            return text.attributes(at: range.location - 1, effectiveRange: nil)
        }
        if text.length > 0 {
            return text.attributes(at: 0, effectiveRange: nil)
        }
        return textView.typingAttributes
    }

    func activate(_ textView: UITextView, segmentID: UUID) {
        self.textView = textView
        activeID = segmentID
        syncState()
    }

    /// Ignored unless this really is the run that was active — otherwise moving
    /// the caret from one run to the next would read as editing having stopped,
    /// and the format bar would blink.
    func deactivate(_ textView: UITextView) {
        guard self.textView === textView else { return }
        isEditing = false
    }

    func focus(_ segmentID: UUID, at location: Int) {
        focusRequest = FocusRequest(segmentID: segmentID, location: location)
    }

    func endEditing() {
        textView?.resignFirstResponder()
        syncState()
    }

    // MARK: Editing

    /// Levels apply to whole paragraphs, the way they read. Bold, italic and
    /// underline carry across unchanged.
    func apply(level newLevel: TextLevel) {
        style { textView in
            let text = NSMutableAttributedString(attributedString: textView.attributedText)
            let paragraph = (text.string as NSString).paragraphRange(for: textView.selectedRange)

            if paragraph.length > 0 {
                text.enumerateAttributes(in: paragraph, options: []) { attributes, range, _ in
                    text.setAttributes(
                        RichText.attributes(
                            level: newLevel,
                            bold: RichText.isBold(in: attributes),
                            italic: RichText.isItalic(in: attributes),
                            underlined: RichText.isUnderlined(in: attributes)
                        ),
                        range: range
                    )
                }
                replace(textView, with: text)
            }
            level = newLevel
        }
    }

    func toggleBold() { setInline(bold: !isBold, italic: isItalic, underlined: isUnderlined) }
    func toggleItalic() { setInline(bold: isBold, italic: !isItalic, underlined: isUnderlined) }
    func toggleUnderline() { setInline(bold: isBold, italic: isItalic, underlined: !isUnderlined) }

    private func setInline(bold: Bool, italic: Bool, underlined: Bool) {
        style { textView in
            let selection = textView.selectedRange

            if selection.length > 0 {
                let text = NSMutableAttributedString(attributedString: textView.attributedText)
                text.enumerateAttributes(in: selection, options: []) { attributes, range, _ in
                    text.setAttributes(
                        RichText.attributes(
                            level: RichText.level(in: attributes),
                            bold: bold,
                            italic: italic,
                            underlined: underlined
                        ),
                        range: range
                    )
                }
                replace(textView, with: text)
            }

            isBold = bold
            isItalic = italic
            isUnderlined = underlined
        }
    }

    /// Runs an edit with read-back suppressed, then writes the resulting
    /// typing attributes once.
    private func style(_ edit: (UITextView) -> Void) {
        guard let textView else { return }
        isStyling = true
        edit(textView)
        textView.typingAttributes = RichText.attributes(
            level: level, bold: isBold, italic: isItalic, underlined: isUnderlined, ink: inkColor
        )
        isStyling = false
    }

    /// Replacing the whole string resets the caret, so it is put back.
    private func replace(_ textView: UITextView, with text: NSAttributedString) {
        let selection = textView.selectedRange
        textView.attributedText = text
        textView.selectedRange = selection
    }
}
