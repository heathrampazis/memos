import Foundation
import SwiftUI
import UIKit

/// A bookmark, sitting where the URL was typed.
///
/// Compact rather than a hero card: a note is mostly writing, and a link that
/// takes a third of the screen buries the sentence that explains why it is
/// there.
struct LinkWidget: View {
    @Binding var link: LinkBlock
    let color: TileColor

    @Environment(\.openURL) private var openURL
    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        Button(action: open) {
            HStack(spacing: 12) {
                thumbnail

                VStack(alignment: .leading, spacing: 3) {
                    Text(link.displayTitle)
                        .font(Typography.rowTitle)
                        .foregroundStyle(color.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(link.host)
                        .font(Typography.tileFooter)
                        .foregroundStyle(color.inkTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(color.inkTertiary)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.ink.opacity(0.10))
        )
        .task { await load() }
    }

    private static let thumbnailSize: CGFloat = 46

    private var thumbnail: some View {
        Group {
            if let image {
                // Given the square as its layout size before it is clipped.
                // Filling without one lets a wide banner overflow and carry its
                // own rounding out with it, which is what left the icon looking
                // rectangular.
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
            } else if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(color.inkTertiary)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color.inkTertiary)
            }
        }
        .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
        .background(color.ink.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func open() {
        guard let url = URL(string: link.url) else { return }
        openURL(url)
    }

    private func load() async {
        if link.hasImage, image == nil {
            image = LinkStore.load(link.id)
        }
        guard !link.fetched else { return }

        isLoading = true
        defer { isLoading = false }

        // Marked as attempted either way: a page with no title would otherwise
        // be looked up again every time the note was opened.
        guard let preview = await LinkMetadata.fetch(link.url) else {
            link.fetched = true
            return
        }

        if let data = preview.imageData, LinkStore.write(data, id: link.id) {
            link.hasImage = true
            image = LinkStore.load(link.id)
        }

        link.title = preview.title
        link.fetched = true
        link.revision += 1
    }
}

extension Binding where Value == LinkBlock? {
    func required() -> Binding<LinkBlock> {
        Binding<LinkBlock>(
            get: { self.wrappedValue ?? LinkBlock(id: UUID(), url: "") },
            set: { self.wrappedValue = $0 }
        )
    }
}
