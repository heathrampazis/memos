import Foundation
import SwiftUI

/// A sticky note. Takes plain values and a content slot — never a model type,
/// so it can be used by the board, search, previews and the widget alike.
struct StickyCard<Content: View>: View {
    var color: TileColor = TilePalette.color(0)
    var tilt: Double = 0
    @ViewBuilder var content: Content

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Spacing.cardRadius, style: .continuous)
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(Spacing.cardPadding)
            .background(shape.fill(color.fill))
            .overlay {
                if let edge = color.edge {
                    shape.strokeBorder(edge, lineWidth: 1)
                }
            }
            .background(
                shape
                    .fill(color.shadow)
                    .offset(y: Spacing.cardShadowOffset)
            )
            .rotationEffect(.degrees(tilt))
    }
}

#Preview {
    HStack(spacing: Spacing.gridGap) {
        StickyCard(color: TilePalette.color(0), tilt: -1) {
            Text("Paper").font(Typography.tileTitle)
        }
        StickyCard(color: TilePalette.color(1), tilt: 0.8) {
            Text("Yellow").font(Typography.tileTitle)
        }
        StickyCard(color: TilePalette.color(5), tilt: -0.6) {
            Text("Blue").font(Typography.tileTitle)
        }
    }
    .frame(height: 160)
    .padding(Spacing.screen)
    .background(Theme.canvas)
}
