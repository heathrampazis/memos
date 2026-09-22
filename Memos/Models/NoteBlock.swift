import Foundation
import UIKit

// A tile's body seen as one flat list: every paragraph of writing and every
// widget, in the order they appear on screen.
enum NoteBlock {
    case paragraph(NSAttributedString)
    case widget(TileSegment)
}

extension Array where Element == TileSegment {
    // Flattening is what makes moving a widget simple. Segment boundaries shift
    // as runs join and split, block positions do not.
    var blocks: [NoteBlock] {
        var result: [NoteBlock] = []

        for segment in self {
            if segment.isText {
                for paragraph in segment.text.paragraphs {
                    result.append(.paragraph(paragraph))
                }
            } else {
                result.append(.widget(segment))
            }
        }

        return result
    }

    // Neighbouring paragraphs collapse back into one run. Widgets keep the
    // identity they arrived with, so their views and stored files survive, and
    // runs whose text came through untouched are handed their old id back so
    // their text views are not torn down and rebuilt around the change.
    static func from(blocks: [NoteBlock], reusing old: [TileSegment] = []) -> [TileSegment] {
        var segments: [TileSegment] = []
        var pending = NSMutableAttributedString()

        var spare: [TileSegment] = []
        for segment in old where segment.isText {
            spare.append(segment)
        }

        func closeRun() {
            let text = NSAttributedString(attributedString: pending)

            // A run whose text is unchanged is handed its old id back, so SwiftUI keeps
            // the text view that is already on screen instead of building a new one. Each
            // spare is claimed once, hence removing it as it is taken.
            var reusedID: UUID? = nil
            for index in 0..<spare.count {
                if spare[index].text == text {
                    reusedID = spare.remove(at: index).id
                    break
                }
            }

            let id = reusedID ?? UUID()
            segments.append(TileSegment(id: id, text: text))
            pending = NSMutableAttributedString()
        }

        for block in blocks {
            switch block {
            case .paragraph(let text):
                pending.endLine()
                pending.append(text)
            case .widget(let widget):
                closeRun()
                segments.append(widget)
            }
        }
        closeRun()

        segments.normalise()
        return segments
    }
}

extension NSMutableAttributedString {
    // The last paragraph of a run carries no newline of its own, so whatever
    // follows it would otherwise be welded onto the same line. The break takes
    // the attributes of the line it ends: a paragraph's level lives there, and a
    // bare newline would drop a heading or a list marker.
    fileprivate func endLine() {
        let string = self.string as NSString
        guard length > 0, string.character(at: length - 1) != 0x000A else { return }
        let carried = attributes(at: length - 1, effectiveRange: nil)
        append(NSAttributedString(string: "\n", attributes: carried))
    }
}

extension NSAttributedString {
    // Every paragraph but the last carries its own trailing newline. A text
    // ending in one gets a final empty paragraph: the blank line the caret sits
    // on, and a place a widget can be dropped.
    var paragraphs: [NSAttributedString] {
        let string = self.string as NSString
        var result: [NSAttributedString] = []
        var index = 0

        while index < string.length {
            let range = string.paragraphRange(for: NSRange(location: index, length: 0))
            guard range.length > 0 else { break }
            result.append(attributedSubstring(from: range))
            index = NSMaxRange(range)
        }

        let endsOpen = string.length == 0 || string.character(at: string.length - 1) == 0x000A
        if endsOpen { result.append(NSAttributedString()) }
        return result
    }
}

extension Array where Element == NoteBlock {
    func index(ofWidget id: UUID) -> Int? {
        for index in 0..<count {
            guard case .widget(let widget) = self[index] else { continue }
            if widget.id == id {
                return index
            }
        }
        return nil
    }
}
