import SwiftUI

/// Adds a widget to a tile — audio, a drawing, a panel. The button is the
/// whole of this ticket; what it opens comes later, so the action is injected
/// and currently does nothing.
struct AddWidgetButton: View {
    let color: TileColor
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
        }
        .buttonStyle(AddWidgetButtonStyle(color: color))
        .accessibilityLabel("Add widget")
    }
}

private struct AddWidgetButtonStyle: ButtonStyle {
    let color: TileColor

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        return configuration.label
            // Ink ground with the tile's colour punched out, the same way the
            // format bar draws an active control.
            .foregroundStyle(color.fill)
            .frame(width: Spacing.addWidgetButton, height: Spacing.addWidgetButton)
            .background(Circle().fill(color.ink.opacity(pressed ? 0.82 : 1)))
            .scaleEffect(pressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: pressed)
    }
}
