import Foundation
import SwiftUI
import UIKit

// Owns the text view and every edit made to it.
@Observable
final class RichTextController {
    weak var textView: UITextView?

    // Text colour for the tile this editor is showing.
    var inkColor: UIColor = UIColor(Theme.ink)

    // The tile's own colour, used for whatever is drawn on top of ink — the tick inside a
    // filled checkbox.
    var fillColor: UIColor = .white

    private(set) var level: TextLevel = .body
    private(set) var isBold = false
    private(set) var isItalic = false
    private(set) var isUnderlined = false
    private(set) var isEditing = false
    private(set) var list: TextListKind?

    // Which run of the note holds the caret.
    private(set) var activeID: UUID?

    // Asks a particular run to take the caret.
    var focusRequest: FocusRequest?

    struct FocusRequest: Equatable {
        let segmentID: UUID
        let location: Int
    }

    // While we are rewriting attributes ourselves, the caret moves and UIKit reports changes we
    // would otherwise read back and undo.
    private var isStyling = false

    // MARK: Reading the caret

    func syncState() {
        guard let textView, !isStyling else { return }
        isEditing = textView.isFirstResponder

        let inline = attributesAtCaret(in: textView)
        let paragraph = paragraphAttributes(in: textView)

        // Level, list and tick belong to the paragraph; bold, italic and
        // underline belong to the characters.
        //
        // Reading the level from behind the caret meant that on an empty line
        // it read the break that ended the paragraph above — which is how a
        // quote's indent kept following the caret out of the quote.
        level = RichText.level(in: paragraph)
        list = RichText.list(in: paragraph)

        isBold = RichText.isBold(in: inline)
        isItalic = RichText.isItalic(in: inline)
        isUnderlined = RichText.isUnderlined(in: inline)

        // Put the full set back. UIKit rebuilds typingAttributes from nearby
        // text whenever the caret moves and does not carry custom keys across,
        // so without this the level is lost the moment you move.
        textView.typingAttributes = RichText.attributes(
            level: level,
            bold: isBold,
            italic: isItalic,
            underlined: isUnderlined,
            list: list,
            checked: RichText.isChecked(in: paragraph),
            ink: inkColor
        )
    }

    // The text is the source of truth, not typingAttributes.
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

    // The attributes of the caret's paragraph.
    private func paragraphAttributes(in textView: UITextView) -> [NSAttributedString.Key: Any] {
        let text = textView.attributedText ?? NSAttributedString()
        let paragraph = (text.string as NSString).paragraphRange(for: textView.selectedRange)
        guard paragraph.length > 0, paragraph.location < text.length else {
            return textView.typingAttributes
        }
        return text.attributes(at: paragraph.location, effectiveRange: nil)
    }

    // A paragraph without the break that ends it.
    private func contentRange(of paragraph: NSRange, in string: NSString) -> NSRange {
        guard paragraph.length > 0 else { return paragraph }

        let last = NSMaxRange(paragraph) - 1
        let character = string.substring(with: NSRange(location: last, length: 1))
        guard character == "\n" || character == "\r" else { return paragraph }

        return NSRange(location: paragraph.location, length: paragraph.length - 1)
    }

    // Leaves a paragraph's closing break carrying nothing but body.
    private func neutralise(_ paragraph: NSRange, content: NSRange, in text: NSMutableAttributedString) {
        guard content.length < paragraph.length else { return }
        text.setAttributes(
            RichText.attributes(level: .body, ink: inkColor),
            range: NSRange(location: NSMaxRange(content), length: paragraph.length - content.length)
        )
    }

    func activate(_ textView: UITextView, segmentID: UUID) {
        self.textView = textView
        activeID = segmentID
        syncState()
    }

    // Ignored unless this really is the run that was active — otherwise moving the caret from
    // one run to the next would read as editing having stopped, and the format bar would blink.
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

    // Levels apply to whole paragraphs, the way they read.
    func apply(level newLevel: TextLevel) {
        style { textView in
            let text = NSMutableAttributedString(attributedString: textView.attributedText)
            let string = text.string as NSString
            let paragraph = string.paragraphRange(for: textView.selectedRange)

            // Titles and headings are not list items, so choosing one ends the
            // list the caret was in.
            let keptList = newLevel == .body ? list : nil

            if paragraph.length > 0 {
                let content = contentRange(of: paragraph, in: string)

                if content.length > 0 {
                    text.enumerateAttributes(in: content, options: []) { attributes, range, _ in
                        text.setAttributes(
                            RichText.attributes(
                                level: newLevel,
                                bold: RichText.isBold(in: attributes),
                                italic: RichText.isItalic(in: attributes),
                                underlined: RichText.isUnderlined(in: attributes),
                                list: keptList,
                                checked: RichText.isChecked(in: attributes),
                                ink: inkColor
                            ),
                            range: range
                        )
                    }
                }
                neutralise(paragraph, content: content, in: text)
                replace(textView, with: text)
            }
            level = newLevel
            list = keptList
        }
    }

    // Lists apply to whole paragraphs.
    func toggle(list kind: TextListKind) {
        let newList: TextListKind? = list == kind ? nil : kind

        style { textView in
            let text = NSMutableAttributedString(attributedString: textView.attributedText)
            let string = text.string as NSString
            let span = string.paragraphRange(for: textView.selectedRange)

            var index = span.location
            while index < NSMaxRange(span) {
                let paragraph = string.paragraphRange(for: NSRange(location: index, length: 0))
                setList(newList, on: paragraph, in: text)
                if paragraph.length == 0 { break }
                index = NSMaxRange(paragraph)
            }

            if text.length > 0 { replace(textView, with: text) }
            list = newList
            level = .body
        }
    }

    // Takes the caret's paragraph out of its list, leaving the text alone.
    func clearList() {
        style { textView in
            let text = NSMutableAttributedString(attributedString: textView.attributedText)
            let paragraph = (text.string as NSString).paragraphRange(for: textView.selectedRange)
            setList(nil, on: paragraph, in: text)
            if text.length > 0 { replace(textView, with: text) }
            list = nil
            level = .body
        }
    }

    // A paragraph with nothing typed into it yet.
    func isParagraphEmpty(in textView: UITextView) -> Bool {
        let string = (textView.text ?? "") as NSString
        let paragraph = string.paragraphRange(for: textView.selectedRange)
        guard paragraph.length > 0 else { return true }
        return string
            .substring(with: paragraph)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    // The visual line the caret is on, which inside a quote is not the same thing as its
    // paragraph: a quote keeps all its lines in one paragraph so they sit as close together as
    // any others.
    func isLineEmpty(in textView: UITextView) -> Bool {
        let string = (textView.text ?? "") as NSString
        var index = textView.selectedRange.location

        // Walked back by hand rather than asked of lineRange, which misreports
        // the empty line at the very end of a string that finishes with a
        // break — which is exactly where the second return lands.
        while index > 0 {
            let character = string.substring(with: NSRange(location: index - 1, length: 1))
            if character == "\u{2028}" || character == "\n" || character == "\r" { return true }
            if !character.trimmingCharacters(in: .whitespaces).isEmpty { return false }
            index -= 1
        }
        return true
    }

    // True when the caret sits at the first character of its paragraph, which is where
    // backspace means "stop being a list item".
    func isAtParagraphStart(in textView: UITextView) -> Bool {
        let string = (textView.text ?? "") as NSString
        let selection = textView.selectedRange
        guard selection.length == 0 else { return false }
        return string.paragraphRange(for: selection).location == selection.location
    }

    private func setList(_ kind: TextListKind?, on paragraph: NSRange, in text: NSMutableAttributedString) {
        guard paragraph.length > 0 else { return }
        let content = contentRange(of: paragraph, in: text.string as NSString)

        if content.length > 0 {
            text.enumerateAttributes(in: content, options: []) { attributes, range, _ in
                text.setAttributes(
                    RichText.attributes(
                        level: kind == nil ? RichText.level(in: attributes) : .body,
                        bold: RichText.isBold(in: attributes),
                        italic: RichText.isItalic(in: attributes),
                        underlined: RichText.isUnderlined(in: attributes),
                        list: kind,
                        checked: kind == .checklist && RichText.isChecked(in: attributes),
                        ink: inkColor
                    ),
                    range: range
                )
            }
        }
        neutralise(paragraph, content: content, in: text)
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
                            underlined: underlined,
                            list: RichText.list(in: attributes),
                            checked: RichText.isChecked(in: attributes),
                            ink: inkColor
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

    // Runs an edit with read-back suppressed, then writes the resulting typing attributes once.
    private func style(_ edit: (UITextView) -> Void) {
        guard let textView else { return }
        isStyling = true
        edit(textView)
        textView.typingAttributes = RichText.attributes(
            level: level,
            bold: isBold,
            italic: isItalic,
            underlined: isUnderlined,
            list: list,
            ink: inkColor
        )
        isStyling = false
        // Markers are painted on rather than typed in, so a restyle has to ask
        // for the gutter back explicitly.
        textView.setNeedsDisplay()
    }

    // Replacing the whole string resets the caret, so it is put back.
    private func replace(_ textView: UITextView, with text: NSAttributedString) {
        let selection = textView.selectedRange
        textView.attributedText = text
        textView.selectedRange = NSRange(
            location: min(selection.location, text.length),
            length: min(selection.length, max(0, text.length - selection.location))
        )

        // A programmatic edit never reaches the delegate, so without this the
        // binding behind the text view keeps the unstyled text and the note
        // saves without the change.
        textView.delegate?.textViewDidChange?(textView)
    }
}
