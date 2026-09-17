import Foundation
import SwiftData

@Model
final class Tile {
    /// The board is a fixed eight tiles.
    static let boardCapacity = 8

    var title: String

    /// The note body: an ordered list of text runs and widgets, encoded by
    /// NoteCodec. Older tiles hold a bare archived string and still decode.
    var bodyData: Data

    /// Plain-text mirror, kept in step on save. Tile previews and, later,
    /// search read this rather than unarchiving the body.
    var plainText: String

    /// Which slot in the active palette this tile uses. The palette itself is
    /// an app setting, so the same index recolours when the palette changes.
    var colorIndex: Int

    var createdAt: Date
    var updatedAt: Date

    /// Fixed at creation. Generating this during rendering makes tiles
    /// re-tilt on every redraw.
    var tilt: Double

    init(title: String = "") {
        self.title = title
        self.bodyData = Data()
        self.plainText = ""
        self.colorIndex = 0
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
