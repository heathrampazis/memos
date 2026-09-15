import Foundation
import SwiftData

@Model
final class Tile {
    var title: String

    /// The note body as an archived attributed string. Attachments —
    /// drawings, audio, images — will ride along inside the same archive.
    var bodyData: Data

    /// Plain-text mirror, kept in step on save. Tile previews and, later,
    /// search read this rather than unarchiving the body.
    var plainText: String

    var createdAt: Date
    var updatedAt: Date

    /// Fixed at creation. Generating this during rendering makes tiles
    /// re-tilt on every redraw.
    var tilt: Double

    init(title: String = "") {
        self.title = title
        self.bodyData = Data()
        self.plainText = ""
        self.createdAt = .now
        self.updatedAt = .now
        self.tilt = Double.random(in: -1.1...1.1)
    }

    var isBlank: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : title
    }

    func touch() {
        updatedAt = .now
    }
}
