import Foundation
import SwiftUI
import UIKit

/// Owns the text view and every edit made to it. The format bar talks to this
/// rather than to the text, so styling runs through UIKit where the caret,
/// selection and typing attributes already live.
@Observable
final class RichTextController {
    weak var textView: UITextView?

    /// What the caret is currently sitting in, mirrored for the format bar.
    private(set) var level: TextLevel = .body
    private(set) var isBold = false
    private(set) var isItalic = false
    private(set) var isUnderlined = false
    private(set) var isEditing = false

    // MARK: Reading the caret

    func syncState() {
        guard let textView else { return }
        isEditing = textView.isFirstResponder

        let attributes = currentAttributes(in: textView)
        level = RichText.level(in: attributes)

        let font = attributes[.font] as? UIFont
        let traits = font?.fontDescriptor.symbolicTraits ?? []
        isBold = traits.contains(.traitBold)
        isItalic = traits.contains(.traitItalic)

        let underline = attributes[.underlineStyle] as? Int ?? 0
        isUnderlined = underline != 0
    }

    private func currentAttributes(in textView: UITextView) -> [NSAttributedString.Key: Any] {
        let range = textView.selectedRange
        guard range.length > 0 else { return textView.typingAttributes }

        return textView.attributedText.attributes(at: range.location, effectiveRange: nil)
    }

    // MARK: Editing

    /// Levels apply to whole paragraphs, the way they read.
    func apply(level newLevel: TextLevel) {
        guard let textView else { return }
        let text = NSMutableAttributedString(attributedString: textView.attributedText)
        let paragraph = (text.string as NSString).paragraphRange(for: textView.selectedRange)

        text.enumerateAttributes(in: paragraph, options: []) { attributes, range, _ in
            let traits = (attributes[.font] as? UIFont)?.fontDescriptor.symbolicTraits ?? []
            let underlined = (attributes[.underlineStyle] as? Int ?? 0) != 0
            let inline = traits.intersection([.traitBold, .traitItalic])

            text.setAttributes(
                RichText.attributes(level: newLevel, traits: inline, underlined: underlined),
                range: range
            )
        }

        replace(textView, with: text)

        var typing = textView.typingAttributes
        typing[.font] = RichText.font(level: newLevel, traits: currentInlineTraits())
        typing[.paragraphStyle] = newLevel.paragraphStyle
        typing[.memoLevel] = newLevel.rawValue
        textView.typingAttributes = typing

        syncState()
    }

    func toggleBold() { toggle(.traitBold) }
    func toggleItalic() { toggle(.traitItalic) }

    func toggleUnderline() {
        guard let textView else { return }
        let turningOn = !isUnderlined
        let value = turningOn ? NSUnderlineStyle.single.rawValue : 0

        if textView.selectedRange.length > 0 {
            let text = NSMutableAttributedString(attributedString: textView.attributedText)
            text.addAttribute(.underlineStyle, value: value, range: textView.selectedRange)
            replace(textView, with: text)
        }

        var typing = textView.typingAttributes
        typing[.underlineStyle] = value
        textView.typingAttributes = typing

        syncState()
    }

    private func toggle(_ trait: UIFontDescriptor.SymbolicTraits) {
        guard let textView else { return }
        let adding = !currentInlineTraits().contains(trait)

        if textView.selectedRange.length > 0 {
            let text = NSMutableAttributedString(attributedString: textView.attributedText)
            text.enumerateAttribute(.font, in: textView.selectedRange, options: []) { value, range, _ in
                guard let font = value as? UIFont else { return }
                text.addAttribute(.font, value: font.applying(trait, adding: adding), range: range)
            }
            replace(textView, with: text)
        }

        var typing = textView.typingAttributes
        if let font = typing[.font] as? UIFont {
            typing[.font] = font.applying(trait, adding: adding)
        }
        textView.typingAttributes = typing

        syncState()
    }

    private func currentInlineTraits() -> UIFontDescriptor.SymbolicTraits {
        var traits: UIFontDescriptor.SymbolicTraits = []
        if isBold { traits.insert(.traitBold) }
        if isItalic { traits.insert(.traitItalic) }
        return traits
    }

    /// Replacing the whole string resets the caret, so it is put back.
    private func replace(_ textView: UITextView, with text: NSAttributedString) {
        let selection = textView.selectedRange
        textView.attributedText = text
        textView.selectedRange = selection
    }
}

private extension UIFont {
    func applying(_ trait: UIFontDescriptor.SymbolicTraits, adding: Bool) -> UIFont {
        var traits = fontDescriptor.symbolicTraits
        if adding { traits.insert(trait) } else { traits.remove(trait) }
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
