import Foundation
import SwiftUI

/// A sticky note. Takes plain values and a content slot — never a model type,
/// so it can be used by the board, search, previews and the widget alike.
struct StickyCard<Content: View>: View {
    var color: TileColor = TilePalettes.color(0, in: .colour)
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
            .overlay(shape.strokeBorder(color.edge, lineWidth: 1))
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
        StickyCard(color: TilePalettes.color(0, in: .colour), tilt: -1) {
            Text("Paper").font(Typography.tileTitle)
        }
        StickyCard(color: TilePalettes.color(1, in: .colour), tilt: 0.8) {
            Text("Yellow").font(Typography.tileTitle)
        }
        StickyCard(color: TilePalettes.color(5, in: .colour), tilt: -0.6) {
            Text("Blue").font(Typography.tileTitle)
        }
    }
    .frame(height: 160)
    .padding(Spacing.screen)
    .background(Theme.canvas)
}
