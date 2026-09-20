import SwiftUI

// A round icon button on a soft tint of whatever ink it is sitting on.
struct CircleIconButton: View {
    let systemImage: String
    var tint: Color = Theme.ink
    var size: CGFloat = Spacing.circleButton
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
        }
        .buttonStyle(SoftCircleButtonStyle(tint: tint, size: size))
    }
}

struct SoftCircleButtonStyle: ButtonStyle {
    var tint: Color = Theme.ink
    var size: CGFloat = Spacing.circleButton

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        return configuration.label
            .foregroundStyle(tint.opacity(pressed ? 1 : 0.8))
            .frame(width: size, height: size)
            .background(Circle().fill(tint.opacity(pressed ? 0.20 : 0.11)))
            .scaleEffect(pressed ? 0.88 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: pressed)
    }
}

#Preview {
    HStack(spacing: 14) {
        CircleIconButton(systemImage: "chevron.left") {}
        CircleIconButton(systemImage: "ellipsis") {}
        CircleIconButton(systemImage: "chevron.left", size: Spacing.toolbarCircleButton) {}
    }
    .padding(40)
    .background(Theme.canvas)
}
