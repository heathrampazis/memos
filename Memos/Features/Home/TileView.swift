import Foundation
import SwiftUI

// Maps a Tile onto StickyCard.
struct TileView: View {
    let tile: Tile
    let color: TileColor

    // Width kept for the marker column so the text of every line starts in the same place,
    // whether or not that line has a marker.
    private static let markerWidth: CGFloat = 10

    // Decoded away from the render path and held until the note changes. The board redraws on
    // every frame of the jiggle, and decoding a note that often would cost far more than the
    // preview is worth.
    @State private var preview = TilePreview()
    @State private var hasPreview = false

    var body: some View {
        StickyCard(color: color, tilt: tile.tilt) {
            if tile.isBlank {
                blank
            } else {
                filled
            }
        }
        .task(id: tile.updatedAt) {
            preview = TileCodec.preview(tile.bodyData)
            hasPreview = true
        }
    }

    private var blank: some View {
        VStack {
            Spacer()
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color.inkFaint)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var filled: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(tile.displayTitle)
                .font(Typography.tileTitle)
                .foregroundStyle(color.ink)
                .lineLimit(2)

            if hasPreview {
                ForEach(preview.lines) { line in
                    row(for: line)
                }
            } else {
                // The first frame lands before the note has been decoded, so the plain mirror
                // stands in rather than leaving the tile empty for a moment.
                Text(tile.plainText)
                    .font(Typography.tileBody)
                    .foregroundStyle(color.inkSecondary)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)

            if !preview.widgets.isEmpty {
                widgetRow
            }

            Text(tile.updatedAt.formatted(.relative(presentation: .numeric)))
                .font(Typography.tileFooter)
                .foregroundStyle(color.inkTertiary)
        }
    }

    private func row(for line: PreviewLine) -> some View {
        HStack(alignment: .center, spacing: 5) {
            marker(for: line.kind)

            Text(line.text)
                .font(font(for: line.kind))
                .foregroundStyle(ink(for: line.kind))
                .strikethrough(isDone(line.kind), color: color.inkFaint)
                .lineLimit(1)
        }
    }

    // A heading and an ordinary line carry no marker and start at the edge, so an indented
    // list reads as a list at a glance.
    @ViewBuilder
    private func marker(for kind: PreviewLineKind) -> some View {
        switch kind {
        case .bullet:
            Circle()
                .fill(color.inkTertiary)
                .frame(width: 3.5, height: 3.5)
                .frame(width: Self.markerWidth)

        case .numbered(let number):
            Text("\(number).")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(color.inkTertiary)
                .frame(width: Self.markerWidth, alignment: .trailing)

        case .checklist(let done):
            checkbox(done: done)
                .frame(width: Self.markerWidth)

        case .quote:
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(color.inkFaint)
                .frame(width: 2, height: 10)
                .frame(width: Self.markerWidth)

        case .plain, .heading:
            EmptyView()
        }
    }

    // At this size a drawn tick is mud, so a done item is a filled box and struck-through text.
    @ViewBuilder
    private func checkbox(done: Bool) -> some View {
        if done {
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .fill(color.inkTertiary)
                .frame(width: 8, height: 8)
        } else {
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .strokeBorder(color.inkTertiary, lineWidth: 1.2)
                .frame(width: 8, height: 8)
        }
    }

    private var widgetRow: some View {
        HStack(spacing: 6) {
            ForEach(preview.widgets, id: \.self) { widget in
                Image(systemName: widget.symbol)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(color.inkTertiary)
            }
        }
    }

    private func font(for kind: PreviewLineKind) -> Font {
        if kind == .heading {
            return .system(size: 12, weight: .bold)
        }
        return Typography.tileBody
    }

    private func ink(for kind: PreviewLineKind) -> Color {
        if isDone(kind) { return color.inkFaint }
        if kind == .heading { return color.ink }
        if kind == .quote { return color.inkTertiary }
        return color.inkSecondary
    }

    private func isDone(_ kind: PreviewLineKind) -> Bool {
        if case .checklist(let done) = kind { return done }
        return false
    }
}
