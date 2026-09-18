import Foundation
import SwiftUI

enum PanelKind: String, Codable, CaseIterable, Identifiable {
    // The raw values are what sit in saved notes, so `info` keeps its spelling
    // even though it now reads as "Note".
    case info, idea, question, warning

    var id: String { rawValue }

    var label: String {
        switch self {
        case .info: "Note"
        case .idea: "Idea"
        case .question: "Question"
        case .warning: "Warning"
        }
    }

    var symbol: String {
        switch self {
        case .info: "info.circle.fill"
        case .idea: "lightbulb.fill"
        case .question: "questionmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        }
    }

    /// A kind that has since been renamed or dropped reads as a plain note
    /// rather than failing the decode and taking the whole note with it.
    init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = PanelKind(rawValue: raw) ?? .info
    }

    /// Mid-dark by design. Tiles stay light whatever the app's appearance, so
    /// one value each carries on every palette without a second set.
    var accent: Color {
        switch self {
        case .info: Color(hex: 0x2B6CB0)
        case .idea: Color(hex: 0xB07414)
        case .question: Color(hex: 0x6B46C1)
        case .warning: Color(hex: 0xC0451B)
        }
    }
}
