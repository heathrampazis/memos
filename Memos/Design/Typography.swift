import SwiftUI

/// Text styles. Bricolage Grotesque and Hanken Grotesk replace the system
/// font here in M0-2; nothing outside this file needs to change.
enum Typography {
    static let wordmark = Font.system(size: 30, weight: .heavy)
    static let editorTitle = Font.system(size: 27, weight: .heavy)

    static let tileTitle = Font.system(size: 14, weight: .bold)
    static let tileBody = Font.system(size: 12, weight: .medium)
    static let tileFooter = Font.system(size: 10.5, weight: .semibold)

    static let barLabel = Font.system(size: 13, weight: .bold)

    static func block(_ level: TextLevel, bold: Bool) -> Font {
        switch level {
        case .title: .system(size: 24, weight: .heavy)
        case .heading: .system(size: 19, weight: bold ? .heavy : .bold)
        case .body: .system(size: 16, weight: bold ? .bold : .regular)
        }
    }
}
