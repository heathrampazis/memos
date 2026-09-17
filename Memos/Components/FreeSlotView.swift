import SwiftUI

/// An empty place on the board. Tapping it makes a tile.
struct FreeSlotView: View {
    let fill: Color
    let outline: Color
    var action: () -> Void

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Spacing.cardRadius, style: .continuous)
    }

    var body: some View {
        Button(action: action) {
            shape
                .fill(fill)
                .overlay(
                    shape.strokeBorder(outline, style: StrokeStyle(lineWidth: 2, dash: [7, 6]))
                )
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(outline)
                }
        }
        .buttonStyle(FreeSlotButtonStyle())
    }
}

private struct FreeSlotButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
