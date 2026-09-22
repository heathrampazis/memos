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

    // MARK: Preview

    // What the board draws. It decodes as little as it can: the entry list is cheap JSON, and
    // only the text entries needed for the first few lines are ever unarchived. A widget is
    // recognised from its entry alone, so a note full of photos costs almost nothing here.
    static func preview(_ data: Data, lineLimit: Int = 3) -> TilePreview {
        var preview = TilePreview()
        guard !data.isEmpty else { return preview }

        guard let entries = try? JSONDecoder().decode([Entry].self, from: data) else {
            // A note written before the entry list existed is one archived run on its own.
            appendLines(from: RichText.restore(data), to: &preview, limit: lineLimit)
            return preview
        }

        for entry in entries {
            // Widgets are collected however long the note is, so the icon row is complete.
            if let widget = widget(in: entry) {
                add(widget, to: &preview)
                continue
            }

            if preview.lines.count >= lineLimit { continue }

            if let panel = entry.panel {
                let text = panel.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    let line = PreviewLine(id: preview.lines.count, text: text, kind: .plain)
                    preview.lines.append(line)
                }
                continue
            }

            let archived = entry.text ?? Data()
            appendLines(from: RichText.restore(archived), to: &preview, limit: lineLimit)
        }

        return preview
    }

    // One icon per kind: six photos should read as "this note has photos", not as six
    // identical marks in a row.
    private static func add(_ widget: PreviewWidget, to preview: inout TilePreview) {
        for existing in preview.widgets {
            if existing == widget { return }
        }
        preview.widgets.append(widget)
    }

    // An empty widget earns no icon, the same way it earns no line of preview text.
    private static func widget(in entry: Entry) -> PreviewWidget? {
        if let clip = entry.clip {
            if clip.isEmpty { return nil }
            return .audio
        }
        if let drawing = entry.drawing {
            if drawing.isEmpty { return nil }
            return .drawing
        }
        if let photo = entry.photo {
            if photo.isEmpty { return nil }
            return .photo
        }
        if let code = entry.code {
            if code.isEmpty { return nil }
            return .code
        }
        if let table = entry.table {
            if table.summary == nil { return nil }
            return .table
        }
        if let link = entry.link {
            if link.isEmpty { return nil }
            return .link
        }
        return nil
    }

    private static func appendLines(
        from text: NSAttributedString,
        to preview: inout TilePreview,
        limit: Int
    ) {
        var number = 0

        for paragraph in text.paragraphs {
            if preview.lines.count >= limit { return }

            var attributes: [NSAttributedString.Key: Any] = [:]
            if paragraph.length > 0 {
                attributes = paragraph.attributes(at: 0, effectiveRange: nil)
            }

            // Counted before the empty check, so the numbers match the ones the editor draws.
            let list = RichText.list(in: attributes)
            if list == .numbered {
                number += 1
            } else {
                number = 0
            }

            let body = paragraph.string.trimmingCharacters(in: .whitespacesAndNewlines)
            if body.isEmpty { continue }

            let kind = kind(
                list: list,
                level: RichText.level(in: attributes),
                checked: RichText.isChecked(in: attributes),
                number: number
            )
            preview.lines.append(PreviewLine(id: preview.lines.count, text: body, kind: kind))
        }
    }

    private static func kind(
        list: TextListKind?,
        level: TextLevel,
        checked: Bool,
        number: Int
    ) -> PreviewLineKind {
        if let list {
            switch list {
            case .bullet: return .bullet
            case .numbered: return .numbered(number)
            case .checklist: return .checklist(done: checked)
            }
        }

        if level == .title || level == .heading { return .heading }
        if level == .quote { return .quote }
        return .plain
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
            return clip.displayName
        }

        if let panel = segment.panel {
            if panel.text.isEmpty { return nil }
            return panel.text
        }

        if let drawing = segment.drawing {
            if drawing.isEmpty { return nil }
            return "Drawing"
        }

        if let photo = segment.photo {
            if photo.isEmpty { return nil }
            return "Photo"
        }

        if let link = segment.link {
            if link.isEmpty { return nil }
            return link.displayTitle
        }

        if let table = segment.table {
            guard let summary = table.summary else { return nil }
            return summary
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
                return trimmed
            }
        }

        return nil
    }
}
