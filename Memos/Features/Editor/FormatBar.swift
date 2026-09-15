import Foundation
import SwiftUI

/// The editing bar pinned above the keyboard. Everything the editor can do
/// lives here, so there is only one place to look.
struct FormatBar: View {
    let controller: RichTextController

    var body: some View {
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
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Theme.canvas)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.border).frame(height: 1)
        }
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
