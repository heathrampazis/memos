import UIKit
import SwiftUI

enum TextLevel: String, Codable, CaseIterable {
    case title, heading, body

    var label: String {
        switch self {
        case .title: "Title"
        case .heading: "Heading"
        case .body: "Body"
        }
    }

    var baseFont: UIFont {
        switch self {
        case .title: .systemFont(ofSize: 24, weight: .heavy)
        case .heading: .systemFont(ofSize: 19, weight: .bold)
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
    /// Remembers which level a paragraph is, so the bar can reflect the caret
    /// and so styling survives a round trip through storage.
    static let memoLevel = NSAttributedString.Key("memos.level")
}

enum RichText {
    static func attributes(level: TextLevel, traits: UIFontDescriptor.SymbolicTraits, underlined: Bool) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font(level: level, traits: traits),
            .paragraphStyle: level.paragraphStyle,
            .foregroundColor: UIColor(Theme.ink),
            .memoLevel: level.rawValue,
        ]
        if underlined {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        return attributes
    }

    static func font(level: TextLevel, traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let base = level.baseFont
        guard !traits.isEmpty else { return base }

        let merged = base.fontDescriptor.symbolicTraits.union(traits)
        guard let descriptor = base.fontDescriptor.withSymbolicTraits(merged) else { return base }
        return UIFont(descriptor: descriptor, size: base.pointSize)
    }

    static func level(in attributes: [NSAttributedString.Key: Any]) -> TextLevel {
        guard let raw = attributes[.memoLevel] as? String,
              let level = TextLevel(rawValue: raw)
        else { return .body }
        return level
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
