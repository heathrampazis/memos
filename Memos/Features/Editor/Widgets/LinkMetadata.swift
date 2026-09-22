import Foundation
import LinkPresentation
import UIKit

// What came back about a page.
struct LinkPreview: Sendable {
    let title: String
    let imageData: Data?
}

enum LinkMetadata {
    static func fetch(_ address: String) async -> LinkPreview? {
        guard let url = URL(string: address) else { return nil }

        let provider = LPMetadataProvider()
        // A note should not sit on a spinner because one site is slow.
        provider.timeout = 8

        guard let metadata = try? await provider.startFetchingMetadata(for: url) else { return nil }
        return LinkPreview(
            title: metadata.title ?? "",
            imageData: await picture(from: metadata)
        )
    }

    // The page's own image first, its icon second.
    private static func picture(from metadata: LPLinkMetadata) async -> Data? {
        var providers: [NSItemProvider] = []
        if let image = metadata.imageProvider {
            providers.append(image)
        }
        if let icon = metadata.iconProvider {
            providers.append(icon)
        }

        for provider in providers {
            if let image = await load(provider), let data = image.pngData() {
                return data
            }
        }

        return nil
    }

    private static func load(_ provider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                continuation.resume(returning: object as? UIImage)
            }
        }
    }
}
