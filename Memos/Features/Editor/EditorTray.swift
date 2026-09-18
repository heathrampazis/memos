import Foundation
import SwiftUI

/// What the note is doing, which is what the tray shows.
enum EditorTrayMode: Equatable {
    case idle
    case title
    case text
    case panel
    case code
    case table
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
    let codeSession: CodeSession
    var onTable: (TableAction) -> Void

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
            case .code:
                codeRows
            case .table:
                tableRows
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

    /// The keys a software keyboard buries three taps deep, which is most of
    /// what writing code on a phone actually costs.
    private static let symbols = [
        "{", "}", "(", ")", "[", "]", "<", ">", "\"", "'", "=", ";", ":",
        ".", ",", "_", "-", "+", "*", "/", "|", "&", "#", "$", "!", "?",
    ]

    /// Rows and columns get a line each. Each button carries the band it acts
    /// on, so it says "add a row" or "move this column left" on its own — no
    /// labels, and no guessing which line is which.
    private var tableRows: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 5) {
                tableKey(.row, "plus", .addRow)
                tableKey(.row, "arrow.up", .moveRowUp)
                tableKey(.row, "arrow.down", .moveRowDown)
                tableKey(.row, "minus", .deleteRow)
                Spacer(minLength: 0)
                dismissButton
            }
            .frame(height: 38)

            HStack(spacing: 5) {
                tableKey(.column, "plus", .addColumn)
                tableKey(.column, "arrow.left", .moveColumnLeft)
                tableKey(.column, "arrow.right", .moveColumnRight)
                tableKey(.column, "minus", .deleteColumn)
                Spacer(minLength: 0)
            }
            .frame(height: 38)
        }
    }

    private func tableKey(
        _ axis: TableBandGlyph.Axis,
        _ symbol: String,
        _ action: TableAction
    ) -> some View {
        Button {
            onTable(action)
        } label: {
            HStack(spacing: 4) {
                TableBandGlyph(axis: axis, tint: color.ink)
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .black))
            }
            .foregroundStyle(color.ink)
            .padding(.horizontal, 9)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.ink.opacity(0.09))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label(for: action))
    }

    private func label(for action: TableAction) -> String {
        switch action {
        case .addRow: "Add row"
        case .deleteRow: "Delete row"
        case .moveRowUp: "Move row up"
        case .moveRowDown: "Move row down"
        case .addColumn: "Add column"
        case .deleteColumn: "Delete column"
        case .moveColumnLeft: "Move column left"
        case .moveColumnRight: "Move column right"
        }
    }

    private var codeRows: some View {
        VStack(alignment: .leading, spacing: 9) {
            if let token = codeSession.commentToken {
                commentKey(token)
            }
            symbolRow
        }
    }

    /// Commenting a line out is the one code action that is a whole thought
    /// rather than a character, so it gets a labelled button of its own.
    private func commentKey(_ token: String) -> some View {
        Button {
            codeSession.toggleComment()
        } label: {
            HStack(spacing: 6) {
                Text(token)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                Text("Comment")
                    .font(Typography.barLabel)
            }
            .foregroundStyle(color.ink)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Capsule().fill(color.ink.opacity(0.10)))
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
    }

    private var symbolRow: some View {
        HStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    indentKey("arrow.left.to.line", label: "Outdent") { codeSession.outdent() }
                    indentKey("arrow.right.to.line", label: "Indent") { codeSession.indent() }

                    ForEach(Self.symbols, id: \.self) { symbol in
                        symbolKey(symbol)
                    }
                }
                .padding(.trailing, 4)
            }

            dismissButton
        }
        .frame(height: 40)
    }

    private func indentKey(
        _ symbol: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color.ink)
                .frame(width: 44, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.ink.opacity(0.09))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func symbolKey(_ symbol: String) -> some View {
        Button {
            codeSession.insert(symbol)
        } label: {
            Text(symbol)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(color.ink)
                .frame(width: 36, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.ink.opacity(0.09))
                )
        }
        .buttonStyle(.plain)
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

/// Three bands with the middle one solid: stacked for a row, side by side for a
/// column. Small enough to sit beside an action symbol and still say which axis
/// the button belongs to.
struct TableBandGlyph: View {
    enum Axis {
        case row, column
    }

    let axis: Axis
    let tint: Color

    var body: some View {
        Group {
            switch axis {
            case .row:
                VStack(spacing: 1.5) { bands }
            case .column:
                HStack(spacing: 1.5) { bands }
            }
        }
        .frame(width: 14, height: 14)
    }

    @ViewBuilder
    private var bands: some View {
        band(0.3)
        band(1)
        band(0.3)
    }

    private func band(_ opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 1, style: .continuous)
            .fill(tint.opacity(opacity))
    }
}
