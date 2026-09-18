import Foundation
import PencilKit
import UIKit

// Where sketches live, one file per drawing.
enum DrawingStore {
    private static var directory: URL {
        let base = URL.applicationSupportDirectory.appending(path: "Drawings")
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    static func url(for id: UUID) -> URL {
        directory.appending(path: "\(id.uuidString).drawing")
    }

    static func load(_ id: UUID) -> PKDrawing? {
        guard let data = try? Data(contentsOf: url(for: id)) else { return nil }
        return try? PKDrawing(data: data)
    }

    static func save(_ drawing: PKDrawing, id: UUID) {
        try? drawing.dataRepresentation().write(to: url(for: id), options: .atomic)
    }

    static func delete(_ id: UUID) {
        try? FileManager.default.removeItem(at: url(for: id))
    }

        // Rendered from the strokes' own bounds rather than the canvas, so the card frames the
        // drawing instead of whatever empty space it was made in.
    static func image(for id: UUID, scale: CGFloat = 3) -> UIImage? {
        guard let drawing = load(id) else { return nil }
        let bounds = drawing.bounds
        guard !bounds.isNull, !bounds.isEmpty else { return nil }
        return drawing.image(from: bounds.insetBy(dx: -10, dy: -10), scale: scale)
    }
}
