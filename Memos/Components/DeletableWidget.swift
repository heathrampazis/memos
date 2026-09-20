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

    // Set by the press, and only while the finger that earned it is still down.
    @State private var armed = false

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
            // High priority, so that winning it cancels the tap already in flight
            // underneath: running alongside instead let the finger lifting after a
            // hold still count as a tap, which opened the drawing editor on the
            // way into edit mode. It has to stay a bare press — sequencing a drag
            // behind it makes the pair claim every touch the widget gets, and then
            // nothing inside one can be tapped at all.
            .highPriorityGesture(press)
            // Attached from the start, because a gesture that appears once the
            // press has landed never sees the finger already down — which is why
            // carrying cannot simply be switched on with edit mode. It watches
            // every touch and acts on none until the press arms it, so a swipe
            // across a widget still scrolls the page.
            .simultaneousGesture(track)
    }

    // The press only decides that a hold happened. Half a second, failing on 8
    // points of travel, is what tells it apart from the start of a scroll —
    // cheaper than that and scrolling off a widget rearranged the note.
    private var press: some Gesture {
        LongPressGesture(minimumDuration: 0.5, maximumDistance: 8)
            .onEnded { _ in
                armed = true
                onHold()
            }
    }

    // Zero minimum distance, so that this always ends: at 8 it would only report
    // a touch that travelled, and a hold released on the spot would leave the
    // widget armed for the next unrelated swipe.
    private var track: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(space))
            .onChanged { drag in
                guard armed else { return }
                onCarry(drag)
            }
            .onEnded { _ in
                armed = false
                onDrop()
            }
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
