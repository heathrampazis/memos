import Foundation
import UIKit

enum PhotoStore {
    // A note does not need a twelve-megapixel original, and one that kept them would be slow to
    // open and heavy to back up.
    static let maximumEdge: CGFloat = 2000

    private static var directory: URL {
        let base = URL.applicationSupportDirectory.appending(path: "Photos")
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    static func url(for id: UUID) -> URL {
        directory.appending(path: "\(id.uuidString).jpg")
    }

    // Returns the stored size, which is what the card needs to hold its shape.
    static func write(_ data: Data, id: UUID) -> CGSize? {
        guard let image = UIImage(data: data) else { return nil }
        let scaled = downscaled(image)
        guard let jpeg = scaled.jpegData(compressionQuality: 0.85) else { return nil }

        try? jpeg.write(to: url(for: id), options: .atomic)
        return scaled.size
    }

    static func load(_ id: UUID) -> UIImage? {
        UIImage(contentsOfFile: url(for: id).path)
    }

    static func delete(_ id: UUID) {
        try? FileManager.default.removeItem(at: url(for: id))
    }

    private static func downscaled(_ image: UIImage) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maximumEdge else { return image }

        let ratio = maximumEdge / longest
        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)

        // Scale 1, or the renderer would hand back a device-scaled image and
        // quietly undo the resize.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
