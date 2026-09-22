import Foundation

// What the board draws inside a tile: the first few lines of the note, each carrying enough
// of its shape to be recognisable, and one icon per kind of widget the note holds.
struct TilePreview {
    var lines: [PreviewLine] = []
    var widgets: [PreviewWidget] = []

    var isEmpty: Bool {
        lines.isEmpty && widgets.isEmpty
    }
}

struct PreviewLine: Identifiable {
    let id: Int
    let text: String
    let kind: PreviewLineKind
}

enum PreviewLineKind: Equatable {
    case plain
    case heading
    case quote
    case bullet
    case numbered(Int)
    case checklist(done: Bool)
}

// Drawn as a symbol rather than spelled out, so a note full of media does not spend its tile
// on the words "Photo" and "Drawing".
enum PreviewWidget: String {
    case photo, drawing, audio, code, table, link

    var symbol: String {
        switch self {
        case .photo: "photo"
        case .drawing: "scribble"
        case .audio: "waveform"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .table: "tablecells"
        case .link: "link"
        }
    }
}
