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
        var entries: [Entry] = []

        for segment in segments {
            if let clip = segment.clip {
                entries.append(Entry(clip: clip))
            } else if let panel = segment.panel {
                entries.append(Entry(panel: panel))
            } else if let drawing = segment.drawing {
                entries.append(Entry(drawing: drawing))
            } else if let photo = segment.photo {
                entries.append(Entry(photo: photo))
            } else if let code = segment.code {
                entries.append(Entry(code: code))
            } else if let table = segment.table {
                entries.append(Entry(table: table))
            } else if let link = segment.link {
                entries.append(Entry(link: link))
            } else {
                entries.append(Entry(text: RichText.archive(segment.text)))
            }
        }

        guard let data = try? JSONEncoder().encode(entries) else { return Data() }
        return data
    }

    static func decode(_ data: Data) -> [TileSegment] {
        guard !data.isEmpty else { return [TileSegment()] }

        guard let entries = try? JSONDecoder().decode([Entry].self, from: data) else {
            return [TileSegment(text: RichText.restore(data))]
        }

        var segments: [TileSegment] = []

        for entry in entries {
            if let clip = entry.clip {
                segments.append(TileSegment(clip: clip))
            } else if let panel = entry.panel {
                segments.append(TileSegment(panel: panel))
            } else if let drawing = entry.drawing {
                segments.append(TileSegment(drawing: drawing))
            } else if let photo = entry.photo {
                segments.append(TileSegment(photo: photo))
            } else if let code = entry.code {
                segments.append(TileSegment(code: code))
            } else if let table = entry.table {
                segments.append(TileSegment(table: table))
            } else if let link = entry.link {
                segments.append(TileSegment(link: link))
            } else {
                let archived = entry.text ?? Data()
                segments.append(TileSegment(text: RichText.restore(archived)))
            }
        }

        // A body that decoded to nothing still needs one empty run to type into.
        if segments.isEmpty {
            return [TileSegment()]
        }
        return segments
    }

    // The board preview and, later, search read this rather than decoding the body.
    static func plainText(_ segments: [TileSegment]) -> String {
        var lines: [String] = []

        for segment in segments {
            if let line = previewLine(for: segment) {
                lines.append(line)
            }
        }

        return lines.joined(separator: "\n")
    }

    // One line standing in for one segment, or nil when the segment is empty and
    // should not take up a line of the preview at all.
    private static func previewLine(for segment: TileSegment) -> String? {
        if let clip = segment.clip {
            if clip.isEmpty { return nil }
            return "\u{266A} " + clip.displayName
        }

        if let panel = segment.panel {
            if panel.text.isEmpty { return nil }
            return panel.text
        }

        if let drawing = segment.drawing {
            if drawing.isEmpty { return nil }
            return "\u{270E} Drawing"
        }

        if let photo = segment.photo {
            if photo.isEmpty { return nil }
            return "\u{25A3} Photo"
        }

        if let link = segment.link {
            if link.isEmpty { return nil }
            return "\u{2197} " + link.displayTitle
        }

        if let table = segment.table {
            guard let summary = table.summary else { return nil }
            return "\u{25A6} " + summary
        }

        if let code = segment.code {
            return codePreviewLine(for: code)
        }

        let text = segment.text.string.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return nil }
        return text
    }

    // The first line of a snippet says more than the word "code" ever would.
    private static func codePreviewLine(for code: CodeBlock) -> String? {
        guard !code.isEmpty else { return nil }

        for line in code.code.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                return "\u{2039}\u{203A} " + trimmed
            }
        }

        return nil
    }
}
