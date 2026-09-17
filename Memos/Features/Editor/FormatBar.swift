import Foundation
import SwiftUI

/// The editing tray, docked to the bottom of the editor. It stays put whether
/// or not the keyboard is up — mounting and unmounting it resizes the text
/// view underneath, which reflows the note every time editing stops.
///
/// It takes the tile's colour so it reads as part of the note. Controls are
/// drawn in ink, which every tile colour carries at well over 7:1.
struct FormatBar: View {
    let controller: RichTextController
    let color: TileColor

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: Spacing.trayRadius,
            topTrailingRadius: Spacing.trayRadius,
            style: .continuous
        )
    }

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

                separator

                ForEach(TextListKind.allCases, id: \.self) { kind in
                    iconToggle(kind.symbol, isOn: controller.list == kind) {
                        controller.toggle(list: kind)
                    }
                    .accessibilityLabel(kind.label)
                }

                Spacer(minLength: 0)
                dismissButton
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 22)
        .background {
            shape
                .fill(color.tray)
                .overlay(shape.stroke(color.ink.opacity(0.12), lineWidth: 1))
                .padding(.bottom, -Spacing.trayBleed)
        }
        .animation(.easeOut(duration: 0.2), value: color.id)
    }

    private var separator: some View {
        Capsule()
            .fill(color.ink.opacity(0.14))
            .frame(width: 1, height: 20)
            .padding(.horizontal, 3)
    }

    private var dismissButton: some View {
        Button {
            controller.endEditing()
        } label: {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color.ink.opacity(0.55))
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
                .foregroundStyle(active ? color.fill : color.ink)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(
                    Capsule().fill(active ? color.ink : color.ink.opacity(0.10))
                )
        }
        .buttonStyle(.plain)
    }

    private func iconToggle(_ symbol: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isOn ? color.fill : color.ink)
                .frame(width: 42, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(isOn ? color.ink : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}
