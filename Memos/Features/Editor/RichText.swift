import SwiftUI
import UIKit

enum TextLevel: String, Codable, CaseIterable {
    case title, heading, body

    var label: String {
        switch self {
        case .title: "Title"
        case .heading: "Heading"
        case .body: "Body"
        }
    }

    /// Titles and headings carry their weight here. That is not the same thing
    /// as the author pressing bold, and the two must not be confused.
    var baseFont: UIFont {
        switch self {
        case .title: .systemFont(ofSize: 24, weight: .heavy)
        case .heading: .systemFont(ofSize: 19, weight: .semibold)
        case .body: .systemFont(ofSize: 16, weight: .regular)
        }
    }

    var paragraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        switch self {
        case .title:
            style.paragraphSpacing = 6
            style.paragraphSpacingBefore = 10
        case .heading:
            style.paragraphSpacing = 4
            style.paragraphSpacingBefore = 12
        case .body:
            style.lineSpacing = 4
            style.paragraphSpacing = 4
        }
        return style
    }
}

enum TextListKind: String, Codable, CaseIterable {
    case bullet, numbered, checklist

    var symbol: String {
        switch self {
        case .bullet: "list.bullet"
        case .numbered: "list.number"
        case .checklist: "checklist"
        }
    }

    var label: String {
        switch self {
        case .bullet: "Bulleted list"
        case .numbered: "Numbered list"
        case .checklist: "Checklist"
        }
    }
}

extension NSAttributedString.Key {
    /// Which level a paragraph is, so the bar reflects the caret and styling
    /// survives a round trip through storage.
    static let memoLevel = NSAttributedString.Key("memos.level")

    /// Whether the author asked for bold, as opposed to the weight a title or
    /// heading already carries. Reading boldness off the font cannot tell the
    /// two apart, so a heading reports itself bold and hands that to whatever
    /// follows it.
    static let memoBold = NSAttributedString.Key("memos.bold")

    /// Which kind of list a paragraph belongs to. The markers themselves are
    /// drawn, never inserted, so the text stays exactly what the author typed
    /// and numbering never has to be rewritten into the string.
    static let memoList = NSAttributedString.Key("memos.list")

    /// A ticked checklist item.
    static let memoChecked = NSAttributedString.Key("memos.checked")
}

enum RichText {
    static func attributes(
        level: TextLevel,
        bold: Bool = false,
        italic: Bool = false,
        underlined: Bool = false,
        list: TextListKind? = nil,
        checked: Bool = false,
        ink: UIColor = UIColor(Theme.ink)
    ) -> [NSAttributedString.Key: Any] {
        // A list is a body-level thing. A bulleted heading is not a shape this
        // app has, and allowing it makes the marker column wrong for the font.
        let level = list == nil ? level : .body
        let ticked = list == .checklist && checked

        var attributes: [NSAttributedString.Key: Any] = [
            .font: font(level: level, bold: bold, italic: italic),
            .paragraphStyle: paragraphStyle(level: level, list: list),
            .foregroundColor: ticked ? ink.withAlphaComponent(0.45) : ink,
            .memoLevel: level.rawValue,
            .memoBold: bold,
        ]
        if underlined {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        if let list {
            attributes[.memoList] = list.rawValue
            attributes[.memoChecked] = ticked
        }
        if ticked {
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
        return attributes
    }

    /// Indented far enough to clear the marker column, with wrapped lines
    /// landing under the first one rather than under the marker.
    static func paragraphStyle(level: TextLevel, list: TextListKind?) -> NSParagraphStyle {
        guard list != nil,
              let style = level.paragraphStyle.mutableCopy() as? NSMutableParagraphStyle
        else { return level.paragraphStyle }

        style.firstLineHeadIndent = Spacing.listIndent
        style.headIndent = Spacing.listIndent
        style.paragraphSpacing = 2
        return style
    }

    static func font(level: TextLevel, bold: Bool, italic: Bool) -> UIFont {
        let base = level.baseFont
        var traits = base.fontDescriptor.symbolicTraits

        if bold { traits.insert(.traitBold) }
        if italic { traits.insert(.traitItalic) } else { traits.remove(.traitItalic) }

        guard let descriptor = base.fontDescriptor.withSymbolicTraits(traits) else { return base }
        return UIFont(descriptor: descriptor, size: base.pointSize)
    }

    static func level(in attributes: [NSAttributedString.Key: Any]) -> TextLevel {
        guard let raw = attributes[.memoLevel] as? String,
              let level = TextLevel(rawValue: raw)
        else { return .body }
        return level
    }

    static func isBold(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        attributes[.memoBold] as? Bool ?? false
    }

    static func isItalic(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        let traits = (attributes[.font] as? UIFont)?.fontDescriptor.symbolicTraits ?? []
        return traits.contains(.traitItalic)
    }

    static func isUnderlined(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        (attributes[.underlineStyle] as? Int ?? 0) != 0
    }

    static func list(in attributes: [NSAttributedString.Key: Any]) -> TextListKind? {
        guard let raw = attributes[.memoList] as? String else { return nil }
        return TextListKind(rawValue: raw)
    }

    static func isChecked(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        attributes[.memoChecked] as? Bool ?? false
    }

    /// Repaints every run to the given ink, leaving structure untouched.
    static func repainted(_ text: NSAttributedString, ink: UIColor) -> NSAttributedString {
        guard text.length > 0 else { return text }
        let copy = NSMutableAttributedString(attributedString: text)
        let full = NSRange(location: 0, length: copy.length)

        // Ticked items are dimmed, so repainting has to keep them dim rather
        // than restoring them to full ink along with everything else.
        copy.enumerateAttributes(in: full, options: []) { attributes, range, _ in
            let value = isChecked(in: attributes) ? ink.withAlphaComponent(0.45) : ink
            copy.addAttribute(.foregroundColor, value: value, range: range)
        }
        return copy
    }

    /// Archive and restore one run of text. Widgets are their own segments in
    /// NoteCodec, so nothing but text ever reaches this.
    static func archive(_ text: NSAttributedString) -> Data {
        (try? NSKeyedArchiver.archivedData(withRootObject: text, requiringSecureCoding: false)) ?? Data()
    }

    static func restore(_ data: Data) -> NSAttributedString {
        guard !data.isEmpty else { return NSAttributedString() }

        let allowed: [AnyClass] = [
            NSAttributedString.self,
            NSParagraphStyle.self, NSMutableParagraphStyle.self,
            UIFont.self, UIColor.self, NSNumber.self, NSString.self,
        ]
        if let text = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: allowed, from: data)
            as? NSAttributedString {
            return text
        }

        // A secure decode fails whole if any nested class is missing from the
        // list above. Losing a note to that would be worse than reading back an
        // archive this app wrote itself, so fall back rather than return empty.
        guard let reader = try? NSKeyedUnarchiver(forReadingFrom: data) else {
            return NSAttributedString()
        }
        reader.requiresSecureCoding = false
        defer { reader.finishDecoding() }
        return reader.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? NSAttributedString
            ?? NSAttributedString()
    }
}
