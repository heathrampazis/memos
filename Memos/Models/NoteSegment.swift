import Foundation
import UIKit

/// A note is an ordered run of text and widgets, not one string. A widget is a
/// real view in the scroll rather than a character, so a run of text ends
/// wherever a widget begins — recording that split is all this type does.
struct NoteSegment: Identifiable, Equatable {
    let id: UUID
    var text: NSAttributedString
    var clip: AudioClip?

    init(id: UUID = UUID(), text: NSAttributedString = NSAttributedString()) {
        self.id = id
        self.text = text
        self.clip = nil
    }

    init(id: UUID = UUID(), clip: AudioClip) {
        self.id = id
        self.text = NSAttributedString()
        self.clip = clip
    }

    var isText: Bool { clip == nil }
}

/// A recording, minus the audio itself. The samples are the meter readings
/// taken while recording: drawing the waveform from the file would mean
/// decoding it every time the note is opened.
struct AudioClip: Equatable, Codable {
    var id: UUID
    var name: String = ""
    var duration: TimeInterval = 0
    var samples: [Float] = []

    var isEmpty: Bool { duration <= 0 }
    var displayName: String { name.isEmpty ? "Voice memo" : name }
}

/// Reads and writes the segment list as the tile's body. Notes written before
/// widgets existed are a bare archived string, so decoding falls back to
/// treating the whole thing as one run of text.
enum NoteCodec {
    private struct Entry: Codable {
        var text: Data?
        var clip: AudioClip?
    }

    static func encode(_ segments: [NoteSegment]) -> Data {
        let entries = segments.map { segment in
            if let clip = segment.clip {
                return Entry(text: nil, clip: clip)
            }
            return Entry(text: RichText.archive(segment.text), clip: nil)
        }
        return (try? JSONEncoder().encode(entries)) ?? Data()
    }

    static func decode(_ data: Data) -> [NoteSegment] {
        guard !data.isEmpty else { return [NoteSegment()] }

        guard let entries = try? JSONDecoder().decode([Entry].self, from: data) else {
            return [NoteSegment(text: RichText.restore(data))]
        }

        let segments = entries.map { entry -> NoteSegment in
            if let clip = entry.clip { return NoteSegment(clip: clip) }
            return NoteSegment(text: RichText.restore(entry.text ?? Data()))
        }
        return segments.isEmpty ? [NoteSegment()] : segments
    }

    /// The board preview and, later, search read this rather than decoding the
    /// body. A widget counts as content, or a note holding only a recording
    /// would look blank and be thrown away on exit.
    static func plainText(_ segments: [NoteSegment]) -> String {
        segments
            .compactMap { segment -> String? in
                if let clip = segment.clip { return "\u{266A} " + clip.displayName }
                let text = segment.text.string.trimmingCharacters(in: .whitespacesAndNewlines)
                return text.isEmpty ? nil : text
            }
            .joined(separator: "\n")
    }

    static func repainted(_ segments: [NoteSegment], ink: UIColor) -> [NoteSegment] {
        segments.map { segment in
            guard segment.isText else { return segment }
            var copy = segment
            copy.text = RichText.repainted(segment.text, ink: ink)
            return copy
        }
    }
}
