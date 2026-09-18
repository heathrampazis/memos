import Foundation
import SwiftUI

/// What the note is doing, which is what the tray shows.
enum EditorTrayMode: Equatable {
    case idle
    case title
    case text
    case panel
    case insert
}

/// The editing tray, docked to the bottom of the editor.
///
/// One surface, several contents. Writing gets the two formatting rows; the
/// caret in a panel gets that panel's kinds; the (+) floating over the note
/// swaps the whole thing for the widget menu. Nothing is stacked on top of the
/// note and nothing appears while there is nothing to format.
struct EditorTray: View {
    let controller: RichTextController
    let color: TileColor
    let mode: EditorTrayMode
    let panelKind: PanelKind?
    var onPanelKind: (PanelKind) -> Void
    var onChoose: (WidgetChoice) -> Void

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: Spacing.trayRadius,
            topTrailingRadius: Spacing.trayRadius,
            style: .continuous
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch mode {
            case .insert:
                WidgetMenu(color: color, onChoose: onChoose)
            case .text:
                levelRow
                inlineRow
            case .panel:
                panelRow
            case .title, .idle:
                inlineRow
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            shape
                .fill(color.tray)
                .overlay(shape.stroke(color.ink.opacity(0.12), lineWidth: 1))
                .padding(.bottom, -Spacing.trayBleed)
        }
        .animation(.easeOut(duration: 0.22), value: mode)
        .animation(.easeOut(duration: 0.2), value: color.id)
    }

    // MARK: Rows

    /// Paragraph shape, on its own line the way it reads.
    private var levelRow: some View {
        HStack(spacing: 7) {
            ForEach(TextLevel.allCases, id: \.self) { level in
                levelPill(level)
            }
            Spacer(minLength: 0)
        }
    }

    /// Everything that applies to the words being typed, plus the way out.
    private var inlineRow: some View {
        HStack(spacing: 4) {
            if mode == .text {
                iconToggle("bold", isOn: controller.isBold) { controller.toggleBold() }
                iconToggle("italic", isOn: controller.isItalic) { controller.toggleItalic() }
                iconToggle("underline", isOn: controller.isUnderlined) { controller.toggleUnderline() }

                divider

                ForEach(TextListKind.allCases, id: \.self) { kind in
                    iconToggle(kind.symbol, isOn: controller.list == kind) {
                        controller.toggle(list: kind)
                    }
                    .accessibilityLabel(kind.label)
                }
            }

            Spacer(minLength: 0)
            dismissButton
        }
        .frame(height: 40)
    }

    private var panelRow: some View {
        HStack(spacing: 5) {
            ForEach(PanelKind.allCases) { kind in
                panelChip(kind)
            }
            Spacer(minLength: 0)
            dismissButton
        }
        .frame(height: 40)
    }

    // MARK: Controls

    private var divider: some View {
        Capsule()
            .fill(color.ink.opacity(0.14))
            .frame(width: 1, height: 20)
            .padding(.horizontal, 3)
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
                .background(Capsule().fill(active ? color.ink : color.ink.opacity(0.10)))
        }
        .buttonStyle(.plain)
    }

    private func panelChip(_ kind: PanelKind) -> some View {
        let chosen = panelKind == kind

        return Button {
            onPanelKind(kind)
        } label: {
            Image(systemName: kind.symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(chosen ? color.fill : kind.accent)
                .frame(width: 40, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(chosen ? kind.accent : color.ink.opacity(0.09))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(kind.label)
        .accessibilityAddTraits(chosen ? [.isSelected] : [])
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
        .opacity(mode == .idle ? 0 : 1)
        .allowsHitTesting(mode != .idle)
    }

    private func iconToggle(_ symbol: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isOn ? color.fill : color.ink)
                .frame(width: 40, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(isOn ? color.ink : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}
