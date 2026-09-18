import SwiftUI
import UIKit

// Holding a widget puts the note into the same delete mode the board uses: everything wobbles,
// and each one grows an (x) in its corner.
struct DeletableWidget: ViewModifier {
    let isEditing: Bool
    let color: TileColor
    let seed: Int
    var onHold: () -> Void
    var onDismiss: () -> Void
    var onDelete: () -> Void

    func body(content: Content) -> some View {
        content
            // Innermost, so the badge above it stays tappable: while wobbling a
            // tap anywhere on the widget puts the note back rather than
            // reaching the play button or the text field underneath.
            .overlay {
                if isEditing {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onDismiss)
                }
            }
            // Attached before the wobble so the badge swings with the widget.
            // Overlaying afterwards leaves it pinned outside the rotation,
            // drifting against the corner it belongs to.
            .overlay(alignment: .topLeading) { deleteBadge }
            .wobble(isEditing, seed: seed)
            .transition(.scale(scale: 0.72).combined(with: .opacity))
            // High priority, so that recognising it cancels whatever press is
            // already in flight underneath. Running alongside instead lets the
            // finger lifting still count as a tap, which opened the drawing
            // editor on the way into delete mode.
            .highPriorityGesture(
                LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                    guard !isEditing else { return }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onHold()
                }
            )
    }

    // Flat, and a step darker than the tile it sits on, so it belongs to the note rather than
    // being stuck onto it.
    @ViewBuilder
    private var deleteBadge: some View {
        if isEditing {
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(color.ink)
                    .frame(width: 27, height: 27)
                    .background(Circle().fill(color.shadow))
            }
            .buttonStyle(.plain)
            .offset(x: -7, y: -7)
            .transition(.scale(scale: 0.4).combined(with: .opacity))
        }
    }
}

extension View {
    func deletableWidget(
        isEditing: Bool,
        color: TileColor,
        seed: Int,
        onHold: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(
            DeletableWidget(
                isEditing: isEditing,
                color: color,
                seed: seed,
                onHold: onHold,
                onDismiss: onDismiss,
                onDelete: onDelete
            )
        )
    }
}
