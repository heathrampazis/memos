import Foundation
import SwiftUI

// Adds a widget to a tile.
struct AddWidgetButton: View {
    let color: TileColor
    let isOpen: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .rotationEffect(.degrees(isOpen ? 45 : 0))
        }
        .buttonStyle(AddWidgetButtonStyle(color: color))
        .accessibilityLabel(isOpen ? "Close widgets" : "Add to note")
    }
}

private struct AddWidgetButtonStyle: ButtonStyle {
    let color: TileColor

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        return configuration.label
            // Ink ground with the tile's colour punched out, the same way the
            // tray draws an active control.
            .foregroundStyle(color.fill)
            .frame(width: Spacing.addWidgetButton, height: Spacing.addWidgetButton)
            .background(Circle().fill(color.ink.opacity(pressed ? 0.82 : 1)))
            .scaleEffect(pressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: pressed)
    }
}
