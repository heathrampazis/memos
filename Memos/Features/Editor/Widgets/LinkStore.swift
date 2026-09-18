import Foundation
import UIKit

/// Thumbnails for bookmarks. Same arrangement as photos, at a fraction of the
/// size — a card shows it at 46 points and nothing will ever show it bigger.
enum LinkStore {
    static let maximumEdge: CGFloat = 320

    private static var directory: URL {
        let base = URL.applicationSupportDirectory.appending(path: "Links")
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    static func url(for id: UUID) -> URL {
        directory.appending(path: "\(id.uuidString).jpg")
    }

    @discardableResult
    static func write(_ data: Data, id: UUID) -> Bool {
        guard let image = UIImage(data: data) else { return false }
        let scaled = downscaled(image)
        guard let jpeg = scaled.jpegData(compressionQuality: 0.8) else { return false }

        try? jpeg.write(to: url(for: id), options: .atomic)
        return true
    }

    static func load(_ id: UUID) -> UIImage? {
        UIImage(contentsOfFile: url(for: id).path)
    }

    static func delete(_ id: UUID) {
        try? FileManager.default.removeItem(at: url(for: id))
    }

    static func deleteAll(in segments: [NoteSegment]) {
        for segment in segments {
            guard let link = segment.link else { continue }
            delete(link.id)
        }
    }

    private static func downscaled(_ image: UIImage) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maximumEdge else { return image }

        let ratio = maximumEdge / longest
        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
