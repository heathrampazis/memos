import Foundation
import SwiftUI

/// Maps a Tile onto StickyCard. The mapping lives here so the component
/// itself stays model-free.
struct TileView: View {
    let tile: Tile
    let color: TileColor

    var body: some View {
        StickyCard(color: color, tilt: tile.tilt) {
            if tile.isBlank {
                blank
            } else {
                filled
            }
        }
    }

    private var blank: some View {
        VStack {
            Spacer()
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color.inkFaint)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var filled: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(tile.displayTitle)
                .font(Typography.tileTitle)
                .foregroundStyle(color.ink)
                .lineLimit(2)

            Text(tile.plainText)
                .font(Typography.tileBody)
                .foregroundStyle(color.inkSecondary)
                .lineLimit(4)

            Spacer(minLength: 0)

            Text(tile.updatedAt.formatted(.relative(presentation: .numeric)))
                .font(Typography.tileFooter)
                .foregroundStyle(color.inkTertiary)
        }
    }
}
