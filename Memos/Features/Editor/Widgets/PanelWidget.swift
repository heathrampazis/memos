import Foundation
import SwiftUI

/// A callout sitting between two runs of text. It wears the same ground as the
/// voice memo so the note reads as one object; the kind is carried by the rule
/// and the header, which is enough to tell them apart at a glance.
struct PanelWidget: View {
    @Binding var panel: PanelBlock
    let color: TileColor

    /// The tray shows this panel's kinds while its text has the caret, so it
    /// has to be told when that starts and stops.
    var onFocus: (Bool) -> Void

    @FocusState private var focused: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(panel.kind.accent)
                .frame(width: 3.5)

            VStack(alignment: .leading, spacing: 5) {
                header
                // Drawn by hand: a TextField prompt renders in a system grey
                // that ignores the tile's ink and vanishes on the paler tiles.
                TextField("", text: $panel.text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(Typography.block(.body, bold: false))
                    .foregroundStyle(color.ink)
                    .focused($focused)
                    .overlay(alignment: .topLeading) {
                        if panel.text.isEmpty {
                            Text("Write something…")
                                .font(Typography.block(.body, bold: false))
                                .foregroundStyle(color.inkTertiary)
                                .allowsHitTesting(false)
                        }
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.ink.opacity(0.10))
        )
        .animation(.easeOut(duration: 0.18), value: panel.kind)
        .onChange(of: focused) { _, isFocused in onFocus(isFocused) }
        // A panel is inserted empty, so the caret belongs in it straight away.
        .onAppear {
            guard panel.text.isEmpty else { return }
            // Focus set during the pass that inserted the panel does not stick.
            DispatchQueue.main.async { focused = true }
        }
    }

    private var header: some View {
        Menu {
            ForEach(PanelKind.allCases) { kind in
                Button {
                    panel.kind = kind
                } label: {
                    Label(kind.label, systemImage: kind.symbol)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: panel.kind.symbol)
                    .font(.system(size: 12.5, weight: .bold))
                Text(panel.kind.label)
                    .font(Typography.barLabel)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8.5, weight: .black))
                    .opacity(0.55)
            }
            .foregroundStyle(panel.kind.accent)
            // The longer names get squeezed by the text field below otherwise,
            // and a truncated "Warning" is the one label you cannot lose.
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Panel type, \(panel.kind.label)")
    }
}

extension Binding where Value == PanelBlock? {
    /// ForEach hands back a binding to the whole segment; the card only wants
    /// the panel, and it is only ever built when one is there.
    func required() -> Binding<PanelBlock> {
        Binding<PanelBlock>(
            get: { self.wrappedValue ?? PanelBlock(id: UUID()) },
            set: { self.wrappedValue = $0 }
        )
    }
}
