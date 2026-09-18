import Foundation
import UIKit

// The text view inside a code block, and everything that makes typing code on a phone bearable.
final class CodeTextView: UITextView {
    var language: CodeLanguage = .plain

    static let tab = "    "

    private static let pairs: [Character: Character] = [
        "(": ")", "[": "]", "{": "}", "\"": "\"", "'": "'", "`": "`",
    ]
    private static let closers: Set<String> = [")", "]", "}", "\"", "'", "`"]

    // MARK: Typing

    override func insertText(_ text: String) {
        if text == "\n" {
            openLine()
            return
        }

        guard text.count == 1, let character = text.first, selectedRange.length == 0 else {
            super.insertText(text)
            return
        }

        // Typing the closer that is already sitting there steps over it rather
        // than doubling it.
        if Self.closers.contains(text), nextCharacter == text {
            selectedRange = NSRange(location: selectedRange.location + 1, length: 0)
            return
        }

        guard let closing = Self.pairs[character] else {
            super.insertText(text)
            return
        }

        // A quote next to a word is an apostrophe, not the start of a string.
        if character == "\"" || character == "'",
           previousCharacter.rangeOfCharacter(from: .alphanumerics) != nil {
            super.insertText(text)
            return
        }

        let caret = selectedRange.location
        super.insertText(text + String(closing))
        selectedRange = NSRange(location: caret + 1, length: 0)
    }

    // Return keeps the line's indentation, adds a level after an opening bracket, and drops a
    // waiting closer onto its own line underneath.
    private func openLine() {
        let source = text as NSString
        let caret = selectedRange.location
        let head = lineHead(before: caret, in: source)

        let indent = String(head.prefix { $0 == " " || $0 == "\t" })
        let trimmed = head.trimmingCharacters(in: .whitespaces)
        let opens = trimmed.hasSuffix("{") || trimmed.hasSuffix("(")
            || trimmed.hasSuffix("[") || trimmed.hasSuffix(":")

        var insertion = "\n" + (opens ? indent + Self.tab : indent)
        let landing = caret + (insertion as NSString).length

        if opens, Self.closers.contains(nextCharacter) {
            insertion += "\n" + indent
        }

        super.insertText(insertion)
        selectedRange = NSRange(location: landing, length: 0)
    }

    // MARK: Deleting

    override func deleteBackward() {
        let caret = selectedRange.location
        guard selectedRange.length == 0, caret > 0 else {
            super.deleteBackward()
            return
        }

        let source = text as NSString
        let before = source.substring(with: NSRange(location: caret - 1, length: 1))

        // An empty pair goes as one.
        if let opener = before.first,
           let closing = Self.pairs[opener],
           nextCharacter == String(closing) {
            edit(NSRange(location: caret - 1, length: 2), with: "", caret: caret - 1)
            return
        }

        // Inside the run of spaces that opens a line, backspace goes back to
        // the previous tab stop instead of picking off one space at a time.
        let head = lineHead(before: caret, in: source)
        guard !head.isEmpty, head.allSatisfy({ $0 == " " }) else {
            super.deleteBackward()
            return
        }

        let step = Self.tab.count
        let removed = head.count % step == 0 ? step : head.count % step
        edit(NSRange(location: caret - removed, length: removed), with: "", caret: caret - removed)
    }

    // MARK: Indenting

    // Lands on the next stop rather than adding a fixed four spaces, so a line already indented
    // two ends up at four and not at six.
    func indentLine() {
        let source = text as NSString
        let caret = selectedRange.location
        let column = lineHead(before: caret, in: source).count
        let step = Self.tab.count

        insertText(String(repeating: " ", count: step - (column % step)))
    }

    // The other direction, which a software keyboard has no key for at all.
    func outdentLine() {
        let source = text as NSString
        let lineStart = lineStart(at: selectedRange.location, in: source)

        var spaces = 0
        while lineStart + spaces < source.length,
              source.substring(with: NSRange(location: lineStart + spaces, length: 1)) == " " {
            spaces += 1
        }
        guard spaces > 0 else { return }

        let step = Self.tab.count
        let removed = spaces % step == 0 ? min(step, spaces) : spaces % step
        edit(
            NSRange(location: lineStart, length: removed),
            with: "",
            caret: max(lineStart, selectedRange.location - removed)
        )
    }

    // MARK: Commenting

    func toggleComment() {
        guard let token = language.comment else { return }

        let source = text as NSString
        let caret = selectedRange.location
        let line = source.lineRange(for: NSRange(location: min(caret, source.length), length: 0))

        // The trailing newline is not part of what gets commented.
        var body = line
        if body.length > 0, source.substring(with: NSRange(location: NSMaxRange(body) - 1, length: 1)) == "\n" {
            body.length -= 1
        }

        let content = source.substring(with: body)
        let indent = String(content.prefix { $0 == " " || $0 == "\t" })
        let trimmed = content.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let replacement: String
        if trimmed.hasPrefix(token.open) {
            var stripped = String(trimmed.dropFirst(token.open.count))
            if let close = token.close, stripped.hasSuffix(close) {
                stripped = String(stripped.dropLast(close.count))
            }
            replacement = indent + stripped.trimmingCharacters(in: .whitespaces)
        } else if let close = token.close {
            replacement = indent + token.open + " " + trimmed + " " + close
        } else {
            replacement = indent + token.open + " " + trimmed
        }

        let shift = (replacement as NSString).length - body.length
        edit(body, with: replacement, caret: max(body.location, caret + shift))
    }

    // MARK: Editing

    // Goes through the text-input path rather than the storage, so the change reaches the
    // delegate — which is what saves the snippet and repaints it.
    private func edit(_ range: NSRange, with string: String, caret: Int) {
        guard let start = position(from: beginningOfDocument, offset: range.location),
              let end = position(from: start, offset: range.length),
              let target = textRange(from: start, to: end)
        else { return }

        replace(target, withText: string)
        selectedRange = NSRange(location: caret, length: 0)
    }

    private func lineStart(at location: Int, in source: NSString) -> Int {
        source.lineRange(for: NSRange(location: min(location, source.length), length: 0)).location
    }

    private func lineHead(before location: Int, in source: NSString) -> String {
        let start = lineStart(at: location, in: source)
        guard location > start else { return "" }
        return source.substring(with: NSRange(location: start, length: location - start))
    }

    private var nextCharacter: String {
        let source = text as NSString
        let caret = selectedRange.location
        guard caret < source.length else { return "" }
        return source.substring(with: NSRange(location: caret, length: 1))
    }

    private var previousCharacter: String {
        let source = text as NSString
        let caret = selectedRange.location
        guard caret > 0, caret <= source.length else { return "" }
        return source.substring(with: NSRange(location: caret - 1, length: 1))
    }
}
