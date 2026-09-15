import SwiftUI
import UIKit

/// A tile on the board, with its press, jiggle and delete affordances.
struct BoardTile: View {
    let tile: Tile
    let index: Int
    let isEditing: Bool
    var onOpen: () -> Void
    var onHold: () -> Void
    var onDelete: () -> Void

    @State private var pressing = false

    var body: some View {
        TileView(tile: tile)
            // The badge is attached before the wobble so it swings with the
            // tile. Overlaying afterwards leaves it pinned outside the
            // rotation, drifting against the corner it belongs to.
            .overlay(alignment: .topLeading) { deleteBadge }
            .scaleEffect(pressing && !isEditing ? 0.95 : 1)
            .wobble(isEditing, seed: index)
            .contentShape(Rectangle())
            .onTapGesture {
                if isEditing { onDelete_noop() } else { onOpen() }
            }
            .onLongPressGesture(minimumDuration: 0.4) {
                guard !isEditing else { return }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onHold()
            } onPressingChanged: { isDown in
                withAnimation(.easeOut(duration: 0.18)) { pressing = isDown }
            }
    }

    /// Tapping a tile while editing does nothing; the board is left the way
    /// the home screen leaves it, where only the badge deletes.
    private func onDelete_noop() {}

    private var color: TileColor {
        TilePalette.color(tile.colorIndex)
    }

    /// Flat, and a step darker than the tile it sits on, so it belongs to the
    /// tile rather than being stuck onto it.
    @ViewBuilder
    private var deleteBadge: some View {
        if isEditing {
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(TileInk.primary)
                    .frame(width: 27, height: 27)
                    .background(Circle().fill(color.shadow))
            }
            .buttonStyle(.plain)
            .offset(x: -5, y: -5)
            .transition(.scale(scale: 0.4).combined(with: .opacity))
        }
    }
}
