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

extension NSAttributedString.Key {
    /// Which level a paragraph is, so the bar reflects the caret and styling
    /// survives a round trip through storage.
    static let memoLevel = NSAttributedString.Key("memos.level")

    /// Whether the author asked for bold, as opposed to the weight a title or
    /// heading already carries. Reading boldness off the font cannot tell the
    /// two apart, so a heading reports itself bold and hands that to whatever
    /// follows it.
    static let memoBold = NSAttributedString.Key("memos.bold")
}

enum RichText {
    static func attributes(
        level: TextLevel,
        bold: Bool = false,
        italic: Bool = false,
        underlined: Bool = false,
        ink: UIColor = UIColor(Theme.ink)
    ) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font(level: level, bold: bold, italic: italic),
            .paragraphStyle: level.paragraphStyle,
            .foregroundColor: ink,
            .memoLevel: level.rawValue,
            .memoBold: bold,
        ]
        if underlined {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        return attributes
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

    /// Repaints every run to the given ink, leaving structure untouched.
    static func repainted(_ text: NSAttributedString, ink: UIColor) -> NSAttributedString {
        guard text.length > 0 else { return text }
        let copy = NSMutableAttributedString(attributedString: text)
        copy.addAttribute(.foregroundColor, value: ink, range: NSRange(location: 0, length: copy.length))
        return copy
    }

    /// Archive and restore. Attachments — drawings, audio, images — travel
    /// inside the same archive once they arrive.
    static func archive(_ text: NSAttributedString) -> Data {
        (try? NSKeyedArchiver.archivedData(withRootObject: text, requiringSecureCoding: false)) ?? Data()
    }

    static func restore(_ data: Data) -> NSAttributedString {
        guard !data.isEmpty,
              let text = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data)
        else { return NSAttributedString() }
        return text
    }
}
