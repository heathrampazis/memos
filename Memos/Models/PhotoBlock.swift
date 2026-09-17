import Foundation

/// A picture in a note. Like a drawing, the bytes live in their own file and
/// the block carries only what the card needs before the image has loaded —
/// the shape, so the note does not jump as photos come in.
struct PhotoBlock: Equatable, Codable {
    var id: UUID
    var isEmpty: Bool = true
    var aspectRatio: Double = 4.0 / 3.0
    var revision: Int = 0
}
