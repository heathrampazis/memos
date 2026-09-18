import Foundation

// A picture in a note.
struct PhotoBlock: Equatable, Codable {
    var id: UUID
    var isEmpty: Bool = true
    var aspectRatio: Double = 4.0 / 3.0
    var revision: Int = 0
}
