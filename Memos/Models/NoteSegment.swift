import Foundation
import UIKit

/// A note is an ordered run of text and widgets, not one string. A widget is a
/// real view in the scroll rather than a character, so a run of text ends
/// wherever a widget begins — recording that split is all this type does.
struct NoteSegment: Identifiable, Equatable {
    let id: UUID
    var text: NSAttributedString
    var clip: AudioClip?
    var panel: PanelBlock?
    var drawing: DrawingBlock?
    var photo: PhotoBlock?
    var code: CodeBlock?
    var table: TableBlock?
    var link: LinkBlock?

    init(id: UUID = UUID(), text: NSAttributedString = NSAttributedString()) {
        self.id = id
        self.text = text
    }

    init(id: UUID = UUID(), clip: AudioClip) {
        self.id = id
        self.text = NSAttributedString()
        self.clip = clip
    }

    init(id: UUID = UUID(), panel: PanelBlock) {
        self.id = id
        self.text = NSAttributedString()
        self.panel = panel
    }

    init(id: UUID = UUID(), drawing: DrawingBlock) {
        self.id = id
        self.text = NSAttributedString()
        self.drawing = drawing
    }

    init(id: UUID = UUID(), photo: PhotoBlock) {
        self.id = id
        self.text = NSAttributedString()
        self.photo = photo
    }

    init(id: UUID = UUID(), code: CodeBlock) {
        self.id = id
        self.text = NSAttributedString()
        self.code = code
    }

    init(id: UUID = UUID(), table: TableBlock) {
        self.id = id
        self.text = NSAttributedString()
        self.table = table
    }

    init(id: UUID = UUID(), link: LinkBlock) {
        self.id = id
        self.text = NSAttributedString()
        self.link = link
    }

    var isText: Bool {
        clip == nil && panel == nil && drawing == nil
            && photo == nil && code == nil && table == nil && link == nil
    }

    /// A widget nothing has been put into yet. Backspace may take one of these;
    /// anything with a recording or writing in it has to be deleted on purpose.
    var isEmptyWidget: Bool {
        if let clip = clip { return clip.isEmpty }
        if let panel = panel { return panel.text.isEmpty }
        if let drawing = drawing { return drawing.isEmpty }
        if let photo = photo { return photo.isEmpty }
        if let code = code { return code.isEmpty }
        if let table = table { return table.isEmpty }
        if let link = link { return link.isEmpty }
        return false
    }
}

/// A callout: an icon, a kind and a line or two of plain text. The kind is the
/// whole of its meaning, so it is picked on insert and changed from the panel's
/// own header rather than buried in a menu somewhere else.
struct PanelBlock: Equatable, Codable {
    var id: UUID
    var kind: PanelKind = .info
    var text: String = ""
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
        var panel: PanelBlock?
        var drawing: DrawingBlock?
        var photo: PhotoBlock?
    var code: CodeBlock?
    var table: TableBlock?
    var link: LinkBlock?
    }

    static func encode(_ segments: [NoteSegment]) -> Data {
        let entries = segments.map { segment in
            if let clip = segment.clip {
                return Entry(clip: clip)
            }
            if let panel = segment.panel {
                return Entry(panel: panel)
            }
            if let drawing = segment.drawing {
                return Entry(drawing: drawing)
            }
            if let photo = segment.photo {
                return Entry(photo: photo)
            }
            if let code = segment.code {
                return Entry(code: code)
            }
            if let table = segment.table {
                return Entry(table: table)
            }
            if let link = segment.link {
                return Entry(link: link)
            }
            return Entry(text: RichText.archive(segment.text))
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
            if let panel = entry.panel { return NoteSegment(panel: panel) }
            if let drawing = entry.drawing { return NoteSegment(drawing: drawing) }
            if let photo = entry.photo { return NoteSegment(photo: photo) }
            if let code = entry.code { return NoteSegment(code: code) }
            if let table = entry.table { return NoteSegment(table: table) }
            if let link = entry.link { return NoteSegment(link: link) }
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
                if let clip = segment.clip {
                    return clip.isEmpty ? nil : "\u{266A} " + clip.displayName
                }
                if let panel = segment.panel {
                    return panel.text.isEmpty ? nil : panel.text
                }
                if let drawing = segment.drawing {
                    return drawing.isEmpty ? nil : "\u{270E} Drawing"
                }
                if let photo = segment.photo {
                    return photo.isEmpty ? nil : "\u{25A3} Photo"
                }
                if let link = segment.link {
                    return link.isEmpty ? nil : "\u{2197} " + link.displayTitle
                }
                if let table = segment.table {
                    return table.summary.map { "\u{25A6} " + $0 }
                }
                if let code = segment.code {
                    // The first line of a snippet says more than the word
                    // "code" ever would.
                    guard !code.isEmpty else { return nil }
                    let first = code.code
                        .split(separator: "\n")
                        .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    return first.map { "\u{2039}\u{203A} " + $0.trimmingCharacters(in: .whitespaces) }
                }
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
