import Foundation

// A recording, minus the audio itself.
struct AudioClip: Equatable, Codable {
    var id: UUID
    var name: String = ""
    var duration: TimeInterval = 0
    var samples: [Float] = []

    var isEmpty: Bool { duration <= 0 }
    var displayName: String { name.isEmpty ? "Voice memo" : name }
}
