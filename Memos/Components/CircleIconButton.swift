import SwiftUI

/// A round icon button on a soft tint of the ink colour. Used for navigation
/// and editor actions, so it works on a white card or a coloured tile alike.
struct CircleIconButton: View {
    let systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
        }
        .buttonStyle(SoftCircleButtonStyle())
    }
}

struct SoftCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        return configuration.label
            .foregroundStyle(Theme.ink.opacity(pressed ? 0.9 : 0.66))
            .frame(width: Spacing.circleButton, height: Spacing.circleButton)
            .background(Circle().fill(Theme.ink.opacity(pressed ? 0.17 : 0.08)))
            .scaleEffect(pressed ? 0.88 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: pressed)
    }
}

#Preview {
    HStack(spacing: 14) {
        CircleIconButton(systemImage: "chevron.left") {}
        CircleIconButton(systemImage: "ellipsis") {}
    }
    .padding(40)
    .background(Theme.card)
}
