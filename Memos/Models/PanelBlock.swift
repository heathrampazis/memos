import Foundation

// A callout: an icon, a kind and a line or two of plain text.
struct PanelBlock: Equatable, Codable {
    var id: UUID
    var kind: PanelKind = .info
    var text: String = ""
}
