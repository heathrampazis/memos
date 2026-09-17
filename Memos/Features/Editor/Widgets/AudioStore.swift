import AVFoundation
import Foundation

/// Where recordings live. Each one is a file named after its id; the note only
/// ever stores the id, so the body stays small and the audio stays on disk.
enum AudioStore {
    private static var directory: URL {
        let base = URL.applicationSupportDirectory.appending(path: "Recordings")
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    static func url(for id: UUID) -> URL {
        directory.appending(path: "\(id.uuidString).m4a")
    }

    static func exists(_ id: UUID) -> Bool {
        FileManager.default.fileExists(atPath: url(for: id).path)
    }

    static func delete(_ id: UUID) {
        try? FileManager.default.removeItem(at: url(for: id))
    }

    /// Called when a tile goes away. Recordings outlive the note that pointed
    /// at them otherwise, and nothing else would ever clean them up.
    static func deleteAll(in segments: [NoteSegment]) {
        for segment in segments {
            guard let clip = segment.clip else { continue }
            delete(clip.id)
        }
    }

    static func formatted(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let whole = Int(seconds.rounded())
        return String(format: "%d:%02d", whole / 60, whole % 60)
    }
}
