import Foundation
import SwiftUI

/// A sticky note. Takes plain values and a content slot — never a model type,
/// so it can be used by the board, search, previews and the widget alike.
struct StickyCard<Content: View>: View {
    var color: Color = Theme.card
    var tilt: Double = 0
    @ViewBuilder var content: Content

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Spacing.cardRadius, style: .continuous)
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(Spacing.cardPadding)
            .background(shape.fill(color))
            .overlay(shape.strokeBorder(Theme.cardEdge, lineWidth: 1))
            .background(
                shape
                    .fill(Theme.cardShadow)
                    .offset(y: Spacing.cardShadowOffset)
            )
            .rotationEffect(.degrees(tilt))
    }
}

#Preview {
    HStack(spacing: Spacing.gridGap) {
        StickyCard(tilt: -1) {
            Text("Kitchen reno").font(Typography.tileTitle)
        }
        StickyCard(tilt: 0.8) {
            Text("Toast for Tom").font(Typography.tileTitle)
        }
    }
    .frame(height: 160)
    .padding(Spacing.screen)
    .background(Theme.canvas)
}
