import Foundation
import SwiftData

@Model
final class Tile {
    var title: String
    var text: String
    var createdAt: Date
    var updatedAt: Date

    /// Fixed at creation. Generating this during rendering makes tiles
    /// re-tilt on every redraw.
    var tilt: Double

    init(title: String = "", text: String = "") {
        self.title = title
        self.text = text
        self.createdAt = .now
        self.updatedAt = .now
        self.tilt = Double.random(in: -1.1...1.1)
    }

    var isBlank: Bool {
        title.trimmed.isEmpty && text.trimmed.isEmpty
    }

    var displayTitle: String {
        title.trimmed.isEmpty ? "Untitled" : title
    }

    func touch() {
        updatedAt = .now
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
