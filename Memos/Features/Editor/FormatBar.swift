import Foundation
import SwiftUI

/// The editing tray, docked to the bottom of the editor. It stays put whether
/// or not the keyboard is up — mounting and unmounting it resizes the text
/// view underneath, which reflows the note every time editing stops.
struct FormatBar: View {
    let controller: RichTextController

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: Spacing.trayRadius,
            topTrailingRadius: Spacing.trayRadius,
            style: .continuous
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 7) {
                    ForEach(TextLevel.allCases, id: \.self) { level in
                        levelPill(level)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 4) {
                    iconToggle("bold", isOn: controller.isBold) { controller.toggleBold() }
                    iconToggle("italic", isOn: controller.isItalic) { controller.toggleItalic() }
                    iconToggle("underline", isOn: controller.isUnderlined) { controller.toggleUnderline() }
                    Spacer(minLength: 0)
                    dismissButton
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .padding(.bottom, 14)
        .background {
            shape
                .fill(Theme.canvas)
                .overlay(shape.stroke(Theme.border, lineWidth: 1))
                .padding(.bottom, -Spacing.trayBleed)
        }
    }

    private var dismissButton: some View {
        Button {
            controller.endEditing()
        } label: {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.muted)
                .frame(width: 42, height: 40)
        }
        .buttonStyle(.plain)
        .opacity(controller.isEditing ? 1 : 0)
        .allowsHitTesting(controller.isEditing)
    }

    private func levelPill(_ level: TextLevel) -> some View {
        let active = controller.level == level

        return Button {
            controller.apply(level: level)
        } label: {
            Text(level.label)
                .font(Typography.barLabel)
                .foregroundStyle(active ? Theme.card : Theme.ink)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(Capsule().fill(active ? Theme.ink : Theme.surface))
        }
        .buttonStyle(.plain)
    }

    private func iconToggle(_ symbol: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isOn ? Theme.card : Theme.ink)
                .frame(width: 42, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(isOn ? Theme.ink : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}
