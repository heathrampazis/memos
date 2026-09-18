import Foundation
import SwiftUI

// A table in a note.
struct TableWidget: View {
    @Binding var block: TableBlock
    @Binding var focus: TableCell?
    let color: TileColor

    @FocusState private var focused: TableCell?
    @State private var available: CGFloat = 0

    private static let minimumColumn: CGFloat = 116

    private var columnWidth: CGFloat {
        guard block.columnCount > 0, available > 0 else { return Self.minimumColumn }
        return max(Self.minimumColumn, available / CGFloat(block.columnCount))
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(block.cells.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, _ in
                            cell(row: rowIndex, column: columnIndex)
                        }
                    }

                    if rowIndex < block.rowCount - 1 {
                        Rectangle()
                            .fill(color.ink.opacity(0.12))
                            .frame(height: 1)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.ink.opacity(0.06))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(color.ink.opacity(0.12), lineWidth: 1)
        )
        // Measured rather than assumed: the card sits inside the note's padding
        // and the widget has no other way to know how much room it has.
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { available = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, width in available = width }
            }
        )
        .onChange(of: focused) { _, cell in focus = cell }
        .onChange(of: focus) { _, cell in
            guard focused != cell else { return }
            focused = cell
        }
    }

    private func cell(row: Int, column: Int) -> some View {
        let position = TableCell(row: row, column: column)
        let isHeader = row == 0
        let isFocused = focused == position
        let outline = cornerShape(row: row, column: column)

        return TextField("", text: text(row, column), axis: .vertical)
            .textFieldStyle(.plain)
            .font(isHeader ? Typography.barLabel : Typography.block(.body, bold: false))
            .foregroundStyle(isHeader ? color.ink : color.inkSecondary)
            .lineLimit(1...4)
            .focused($focused, equals: position)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(width: columnWidth, alignment: .leading)
            .frame(minHeight: 40, alignment: .leading)
            .background(isHeader ? color.ink.opacity(0.09) : Color.clear)
            // Outlined rather than filled: every table editor marks the active
            // cell with a border, and darkening it reads as a selected row.
            //
            // Stroked at double width and clipped to its own shape, which keeps
            // the inner half — a plain border would sit half outside the cell
            // and get shaved off by the table's rounded corners.
            .overlay {
                if isFocused {
                    outline
                        .stroke(color.ink, lineWidth: 4)
                        .clipShape(outline)
                }
            }
            .overlay(alignment: .trailing) {
                if column < block.columnCount - 1 {
                    Rectangle()
                        .fill(color.ink.opacity(0.12))
                        .frame(width: 1)
                }
            }
    }

    // A cell on the edge of the table follows the table's own corner, so the outline curves
    // with it instead of being cut square across it.
    private func cornerShape(row: Int, column: Int) -> UnevenRoundedRectangle {
        let radius: CGFloat = 15
        let lastRow = block.rowCount - 1
        let lastColumn = block.columnCount - 1

        return UnevenRoundedRectangle(
            topLeadingRadius: row == 0 && column == 0 ? radius : 0,
            bottomLeadingRadius: row == lastRow && column == 0 ? radius : 0,
            bottomTrailingRadius: row == lastRow && column == lastColumn ? radius : 0,
            topTrailingRadius: row == 0 && column == lastColumn ? radius : 0,
            style: .continuous
        )
    }

    // Bounds-checked: a binding outlives the row or column it points at by a frame or two
    // whenever one is deleted.
    private func text(_ row: Int, _ column: Int) -> Binding<String> {
        Binding(
            get: {
                guard block.cells.indices.contains(row),
                      block.cells[row].indices.contains(column)
                else { return "" }
                return block.cells[row][column]
            },
            set: { value in
                guard block.cells.indices.contains(row),
                      block.cells[row].indices.contains(column)
                else { return }
                block.cells[row][column] = value
            }
        )
    }
}

extension Binding where Value == TableBlock? {
    func required() -> Binding<TableBlock> {
        Binding<TableBlock>(
            get: { self.wrappedValue ?? TableBlock(id: UUID()) },
            set: { self.wrappedValue = $0 }
        )
    }
}
