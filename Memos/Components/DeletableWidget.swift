import SwiftUI
import UIKit

// Holding a widget puts the note into the same edit mode the board uses:
// everything wobbles, each one grows an (x), and the one under the finger can be
// carried to a better spot.
struct DeletableWidget: ViewModifier {
    let isEditing: Bool
    let isCarried: Bool
    let carryOffset: CGSize
    let color: TileColor
    let seed: Int
    let space: String
    var onHold: () -> Void
    var onDismiss: () -> Void
    var onDelete: () -> Void
    var onCarry: (DragGesture.Value) -> Void
    var onDrop: () -> Void

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
            // A widget being carried holds still: wobbling under the finger
            // reads as the note refusing to be rearranged.
            .wobble(isEditing && !isCarried, seed: seed)
            .transition(.scale(scale: 0.72).combined(with: .opacity))
            .scaleEffect(isCarried ? 1.03 : 1)
            .shadow(color: .black.opacity(isCarried ? 0.18 : 0), radius: 12, y: 6)
            .offset(carryOffset)
            // The carried widget has to track the finger exactly. Any inherited
            // animation turns the drag into a lagging chase.
            .transaction { if isCarried { $0.animation = nil } }
            // High priority, so that recognising it cancels whatever press is
            // already in flight underneath. Running alongside instead lets the
            // finger lifting still count as a tap, which opened the drawing
            // editor on the way into edit mode.
            .highPriorityGesture(hold)
    }

    // One unbroken gesture: the press turns edit mode on, and the drag behind it
    // carries the widget without the finger ever lifting.
    //
    // Two things about it are easy to get wrong. `.first` is not the press
    // landing — it reports the press being *attempted*, from touch-down, and its
    // Bool is true the whole way through, so acting on it wobbles the note the
    // instant a widget is touched. Reaching `.second` is the press succeeding.
    //
    // And the duration has to be a constant. Reading `isEditing` here to shorten
    // it once the note is wobbling rebuilds the gesture at the exact moment the
    // press lands, which resets it and loses the finger that is still down —
    // leaving the widget unmovable until it is held all over again.
    //
    // Long, and failing on 8 points of travel, is what separates it from the
    // start of a scroll: once the press lands the touch belongs to the drag for
    // good and the page can no longer move, so it must not be cheap to win.
    private var hold: some Gesture {
        LongPressGesture(minimumDuration: 0.5, maximumDistance: 8)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(space)))
            .onChanged { phase in
                guard case .second(_, let drag) = phase else { return }
                onHold()
                if let drag { onCarry(drag) }
            }
            .onEnded { _ in onDrop() }
    }

    // Flat, and a step darker than the tile it sits on, so it belongs to the note rather than
    // being stuck onto it.
    @ViewBuilder
    private var deleteBadge: some View {
        if isEditing && !isCarried {
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
