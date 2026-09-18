import SwiftUI
import UIKit

enum TextLevel: String, Codable, CaseIterable {
    case title, heading, body, quote

    // The levels that appear as named pills.
    static let named: [TextLevel] = [.title, .heading, .body]

    var label: String {
        switch self {
        case .title: "Title"
        case .heading: "Heading"
        case .body: "Body"
        case .quote: "Quote"
        }
    }

    var size: CGFloat {
        switch self {
        case .title: 24
        case .heading: 20
        case .body, .quote: 16
        }
    }

    // Titles and headings carry their weight here.
    var weight: UIFont.Weight {
        switch self {
        case .title: .heavy
        case .heading: .bold
        case .body, .quote: .regular
        }
    }

    // What pressing B gives this level.
    var boldWeight: UIFont.Weight {
        switch self {
        case .title: .black
        case .heading: .heavy
        case .body, .quote: .bold
        }
    }

    var baseFont: UIFont {
        .systemFont(ofSize: size, weight: weight)
    }

    // Space above separates a heading from whatever came before it; the much smaller space
    // below keeps it attached to what it introduces.
    var paragraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        switch self {
        case .title:
            style.paragraphSpacingBefore = 20
            style.paragraphSpacing = 8
            style.lineSpacing = 1
        case .heading:
            style.paragraphSpacingBefore = 16
            style.paragraphSpacing = 6
            style.lineSpacing = 1
        case .body:
            style.lineSpacing = 4
            style.paragraphSpacing = 4
        case .quote:
            // Indented clear of its rule, and given room either side so it
            // reads as lifted out of the writing around it.
            style.firstLineHeadIndent = Spacing.quoteIndent
            style.headIndent = Spacing.quoteIndent
            style.paragraphSpacingBefore = 10
            style.paragraphSpacing = 10
            style.lineSpacing = 4
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
    // Which level a paragraph is, so the bar reflects the caret and styling survives a round
    // trip through storage.
    static let memoLevel = NSAttributedString.Key("memos.level")

    // Whether the author asked for bold, as opposed to the weight a title or heading already
    // carries.
    static let memoBold = NSAttributedString.Key("memos.bold")

    // Which kind of list a paragraph belongs to.
    static let memoList = NSAttributedString.Key("memos.list")

    // A ticked checklist item.
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
            .foregroundColor: tint(level: level, ticked: ticked, ink: ink),
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

    // Indented far enough to clear the marker column, with wrapped lines landing under the
    // first one rather than under the marker.
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
        // Bold is a weight, not a trait, so each level keeps its own ladder.
        let base = UIFont.systemFont(
            ofSize: level.size,
            weight: bold ? level.boldWeight : level.weight
        )
        guard italic else { return base }

        let traits = base.fontDescriptor.symbolicTraits.union(.traitItalic)
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

    // Ticked items are struck through and faded; a quote sits a shade back from the writing
    // around it.
    static func tint(level: TextLevel, ticked: Bool, ink: UIColor) -> UIColor {
        if ticked { return ink.withAlphaComponent(0.45) }
        return level == .quote ? ink.withAlphaComponent(0.72) : ink
    }

    // Repaints every run to the given ink, leaving structure untouched.
    static func repainted(_ text: NSAttributedString, ink: UIColor) -> NSAttributedString {
        guard text.length > 0 else { return text }
        let copy = NSMutableAttributedString(attributedString: text)
        let full = NSRange(location: 0, length: copy.length)

        // Ticked items and quotes are dimmed, so repainting has to keep them
        // that way rather than restoring everything to full ink.
        copy.enumerateAttributes(in: full, options: []) { attributes, range, _ in
            let value = tint(
                level: level(in: attributes),
                ticked: isChecked(in: attributes),
                ink: ink
            )
            copy.addAttribute(.foregroundColor, value: value, range: range)
        }
        return copy
    }

    // Archive and restore one run of text.
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
