import Foundation
import SwiftUI

// A sketch in a note.
struct DrawingBlock: Equatable, Codable {
    var id: UUID

    // How tall the card sits in the note, dragged by the handle beneath it.
    var height: Double = 200

    var isEmpty: Bool = true

    // Bumped on every save.
    var revision: Int = 0

    static let minimumHeight: Double = 120
    static let maximumHeight: Double = 460
}

enum DrawingInk: String, Codable, CaseIterable, Identifiable {
    case black, blue, green, red

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .black: Color(hex: 0x1A1A1A)
        case .blue: Color(hex: 0x2B6CB0)
        case .green: Color(hex: 0x2F855A)
        case .red: Color(hex: 0xC53030)
        }
    }
}
