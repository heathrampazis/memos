import Foundation
import UIKit

// Where a widget lands: a place inside one run of text.
struct SegmentInsertion: Equatable {
    let segmentID: UUID
    let location: Int
}

// The surgery a tile's body needs when a widget arrives or leaves. Kept apart
// from the editor because none of it touches SwiftUI, and all of it is easier
// to follow as operations on an array than as methods on a view.
extension Array where Element == TileSegment {
    func index(of id: UUID) -> Int? {
        firstIndex { $0.id == id }
    }

    var lastText: TileSegment? {
        last { $0.isText }
    }

    // A tile always begins and ends with somewhere to type. A widget at either
    // end would otherwise leave no way back into the writing.
    mutating func normalise() {
        if isEmpty { self = [TileSegment()] }
        if first?.isText == false { insert(TileSegment(), at: 0) }
        if last?.isText == false { append(TileSegment()) }
    }

    // Cuts a run of text in two and drops a widget into the gap, removing
    // `replacing` as it goes — the URL a bookmark stands in for, say, or an
    // empty range for a plain split. Returns the run that follows the widget.
    mutating func insert(_ widget: Element, into id: UUID, replacing range: NSRange) -> UUID? {
        guard let index = index(of: id), self[index].isText else { return nil }

        let text = self[index].text
        guard NSMaxRange(range) <= text.length else { return nil }

        let head = text.attributedSubstring(from: NSRange(location: 0, length: range.location))
        let tail = text.attributedSubstring(
            from: NSRange(location: NSMaxRange(range), length: text.length - NSMaxRange(range))
        )

        let following = TileSegment(text: tail)
        self[index].text = head
        insert(contentsOf: [widget, following], at: index + 1)
        return following.id
    }

    // Joins a run of text onto the one above it, into the lower of the two so
    // that the text view holding the caret survives and the keyboard stays up.
    // Returns where the caret should land. Two runs only ever end up adjacent
    // when the widget between them went away.
    mutating func joinBackwards(into id: UUID) -> Int? {
        guard let index = index(of: id), index > 0,
              self[index - 1].isText, self[index].isText
        else { return nil }

        let above = self[index - 1].text
        let joined = NSMutableAttributedString(attributedString: above)
        joined.append(self[index].text)

        self[index].text = joined
        remove(at: index - 1)
        return above.length
    }

    mutating func repaint(ink: UIColor) {
        for index in indices where self[index].isText {
            self[index].text = RichText.repainted(self[index].text, ink: ink)
        }
    }
}
