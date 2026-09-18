import Foundation

// Which cell has the caret.
struct TableCell: Hashable, Codable {
    var row: Int
    var column: Int
}

enum TableAction {
    case addRow, deleteRow, moveRowUp, moveRowDown
    case addColumn, deleteColumn, moveColumnLeft, moveColumnRight
}

// A table in a note.
struct TableBlock: Equatable, Codable {
    var id: UUID
    var cells: [[String]]

    init(id: UUID, columns: Int = 3, rows: Int = 3) {
        self.id = id
        self.cells = Array(
            repeating: Array(repeating: "", count: max(1, columns)),
            count: max(2, rows)
        )
    }

    var rowCount: Int { cells.count }
    var columnCount: Int { cells.first?.count ?? 0 }

    var isEmpty: Bool {
        cells.allSatisfy { row in
            row.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
    }

    // The header, for the board preview.
    var summary: String? {
        guard let header = cells.first else { return nil }
        let titles = header
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return titles.isEmpty ? nil : titles.joined(separator: " \u{00B7} ")
    }

    // MARK: Structure

    mutating func addRow(after index: Int) {
        let row = Array(repeating: "", count: max(1, columnCount))
        cells.insert(row, at: min(max(index + 1, 1), rowCount))
    }

    mutating func addColumn(after index: Int) {
        let target = min(max(index + 1, 0), columnCount)
        for row in cells.indices {
            cells[row].insert("", at: min(target, cells[row].count))
        }
    }

    // The header and one body row are the least that still reads as a table.
    mutating func removeRow(_ index: Int) {
        guard rowCount > 2, cells.indices.contains(index), index > 0 else { return }
        cells.remove(at: index)
    }

    mutating func removeColumn(_ index: Int) {
        guard columnCount > 1 else { return }
        for row in cells.indices where cells[row].indices.contains(index) {
            cells[row].remove(at: index)
        }
    }

    // Body rows only, and never past the header.
    mutating func moveRow(_ index: Int, by offset: Int) {
        let destination = index + offset
        guard index > 0, destination > 0,
              cells.indices.contains(index), cells.indices.contains(destination)
        else { return }
        cells.swapAt(index, destination)
    }

    mutating func moveColumn(_ index: Int, by offset: Int) {
        let destination = index + offset
        guard index >= 0, destination >= 0, destination < columnCount else { return }
        for row in cells.indices where cells[row].indices.contains(index)
            && cells[row].indices.contains(destination) {
            cells[row].swapAt(index, destination)
        }
    }
}
