import Foundation
import SwiftUI

enum PanelKind: String, Codable, CaseIterable, Identifiable {
    case info, note, idea, question, warning

    var id: String { rawValue }

    var label: String {
        switch self {
        case .info: "Info"
        case .note: "Note"
        case .idea: "Idea"
        case .question: "Question"
        case .warning: "Warning"
        }
    }

    var symbol: String {
        switch self {
        case .info: "info.circle.fill"
        case .note: "pencil"
        case .idea: "lightbulb.fill"
        case .question: "questionmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        }
    }

    /// Mid-dark by design. Tiles stay light whatever the app's appearance, so
    /// one value each carries on every palette without a second set.
    var accent: Color {
        switch self {
        case .info: Color(hex: 0x2B6CB0)
        case .note: Color(hex: 0x4A5568)
        case .idea: Color(hex: 0xB07414)
        case .question: Color(hex: 0x6B46C1)
        case .warning: Color(hex: 0xC0451B)
        }
    }
}
