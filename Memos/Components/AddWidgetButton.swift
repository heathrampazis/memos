import Foundation
import SwiftUI

/// Adds a widget to a tile. Pressing it opens a small cluster rather than doing
/// anything itself — voice is the only widget so far, and drawings and panels
/// join the same column when they arrive.
struct AddWidgetButton: View {
    let color: TileColor
    var onAudio: () -> Void

    @State private var isOpen = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if isOpen {
                option("mic.fill", label: "Voice memo") {
                    close()
                    onAudio()
                }
                .transition(
                    .scale(scale: 0.4, anchor: .bottom).combined(with: .opacity)
                )
            }

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) {
                    isOpen.toggle()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .rotationEffect(.degrees(isOpen ? 45 : 0))
            }
            .buttonStyle(WidgetButtonStyle(color: color, diameter: Spacing.addWidgetButton))
            .accessibilityLabel(isOpen ? "Close widgets" : "Add widget")
        }
    }

    private func option(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
        }
        .buttonStyle(WidgetButtonStyle(color: color, diameter: Spacing.widgetOptionButton))
        .accessibilityLabel(label)
    }

    private func close() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            isOpen = false
        }
    }
}

private struct WidgetButtonStyle: ButtonStyle {
    let color: TileColor
    let diameter: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        return configuration.label
            // Ink ground with the tile's colour punched out, the same way the
            // format bar draws an active control.
            .foregroundStyle(color.fill)
            .frame(width: diameter, height: diameter)
            .background(Circle().fill(color.ink.opacity(pressed ? 0.82 : 1)))
            .scaleEffect(pressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: pressed)
    }
}
