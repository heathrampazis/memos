import Foundation
import UIKit

// Reads and writes the segment list as the tile's body.
enum TileCodec {
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

    static func encode(_ segments: [TileSegment]) -> Data {
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

    static func decode(_ data: Data) -> [TileSegment] {
        guard !data.isEmpty else { return [TileSegment()] }

        guard let entries = try? JSONDecoder().decode([Entry].self, from: data) else {
            return [TileSegment(text: RichText.restore(data))]
        }

        let segments = entries.map { entry -> TileSegment in
            if let clip = entry.clip { return TileSegment(clip: clip) }
            if let panel = entry.panel { return TileSegment(panel: panel) }
            if let drawing = entry.drawing { return TileSegment(drawing: drawing) }
            if let photo = entry.photo { return TileSegment(photo: photo) }
            if let code = entry.code { return TileSegment(code: code) }
            if let table = entry.table { return TileSegment(table: table) }
            if let link = entry.link { return TileSegment(link: link) }
            return TileSegment(text: RichText.restore(entry.text ?? Data()))
        }
        return segments.isEmpty ? [TileSegment()] : segments
    }

    // The board preview and, later, search read this rather than decoding the body.
    static func plainText(_ segments: [TileSegment]) -> String {
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
}
