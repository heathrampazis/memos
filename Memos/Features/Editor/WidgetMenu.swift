import Foundation
import SwiftUI

enum WidgetChoice: Hashable, Identifiable {
    case photo
    case drawing
    case voice
    case code
    case table
    case panel(PanelKind)

    var id: String {
        switch self {
        case .photo: "photo"
        case .drawing: "drawing"
        case .voice: "voice"
        case .code: "code"
        case .table: "table"
        case .panel(let kind): "panel.\(kind.rawValue)"
        }
    }

    var label: String {
        switch self {
        case .photo: "Photo"
        case .drawing: "Drawing"
        case .voice: "Voice memo"
        case .code: "Code"
        case .table: "Table"
        case .panel(let kind): kind.label
        }
    }

    var symbol: String {
        switch self {
        case .photo: "photo.fill"
        case .drawing: "scribble.variable"
        case .voice: "mic.fill"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .table: "tablecells.fill"
        case .panel(let kind): kind.symbol
        }
    }

    /// Panels carry their own colour; media widgets take the tile's ink.
    var accent: Color? {
        switch self {
        case .panel(let kind): kind.accent
        default: nil
        }
    }

    static let blocks: [WidgetChoice] = [.photo, .drawing, .voice, .code, .table]
    static let panels: [WidgetChoice] = PanelKind.allCases.map(WidgetChoice.panel)
}

/// Everything that can go in a note, named. A grid rather than a column: it
/// stays the same height as widgets are added, and it has room for the names —
/// which a row of bare circles never did.
///
/// It fills the tray rather than arriving as a sheet, so the (+) swaps what the
/// bar is for instead of stacking another surface on top of the note.
struct WidgetMenu: View {
    let color: TileColor
    var onChoose: (WidgetChoice) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            section("BLOCKS", choices: WidgetChoice.blocks)
            section("PANELS", choices: WidgetChoice.panels)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func section(_ title: String, choices: [WidgetChoice]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Typography.sectionLabel)
                .kerning(0.8)
                .foregroundStyle(color.inkTertiary)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                ForEach(choices) { choice in
                    cell(choice)
                }
            }
        }
    }

    private func cell(_ choice: WidgetChoice) -> some View {
        let tint = choice.accent ?? color.ink

        return Button {
            onChoose(choice)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: choice.symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(tint.opacity(0.12))
                    )

                Text(choice.label)
                    .font(Typography.tileFooter)
                    .foregroundStyle(color.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .buttonStyle(.plain)
    }
}
