import Foundation
import UIKit

// The text view used for one run of a note.
final class EditorTextView: UITextView {
    // Returns true when the editor consumed the press — joined this run onto the one above, or
    // removed the widget between them.
    var onDeleteBackwardAtStart: (() -> Bool)?

    // Backspace at the start of any paragraph. True when it was taken to mean
    // "stop being a list item".
    var onDeleteBackwardAtParagraphStart: (() -> Bool)?

    // Something that could have finished a word just landed — a space, a newline, or a paste.
    var onWordCommitted: (() -> Void)?

    var inkColor: UIColor = .label
    var fillColor: UIColor = .systemBackground

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.delegate = self
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { nil }

    // MARK: Keys

    override func insertText(_ text: String) {
        super.insertText(text)
        guard text == " " || text == "\n" else { return }
        onWordCommitted?()
    }

    override func paste(_ sender: Any?) {
        super.paste(sender)
        onWordCommitted?()
    }

    override func deleteBackward() {
        if selectedRange.length == 0, onDeleteBackwardAtParagraphStart?() == true {
            return
        }
        if selectedRange.location == 0,
           selectedRange.length == 0,
           onDeleteBackwardAtStart?() == true {
            return
        }
        super.deleteBackward()
    }

    // Scrolls the caret into view, and only if it is not already there.
    //
    // scrollRectToVisible was doing this on every keystroke, animated, against
    // a layout that had not caught up with the character just typed — so each
    // scroll was aimed at where the caret used to be, and the next one
    // corrected it. That is the chopping. This moves the least it can, without
    // animation, and does nothing at all when the caret is already showing.
    func revealCaret() {
        guard let range = selectedTextRange, let scroll = enclosingScrollView else { return }

        let caret = caretRect(for: range.end)
        guard caret.isFinite, !caret.isNull else { return }

        let target = convert(caret.insetBy(dx: 0, dy: -8), to: scroll)
        var visible = scroll.bounds.inset(by: scroll.adjustedContentInset)
        visible.size.height -= Spacing.caretClearance
        guard visible.height > 0 else { return }

        var offset = scroll.contentOffset
        if target.maxY > visible.maxY {
            offset.y += target.maxY - visible.maxY
        } else if target.minY < visible.minY {
            offset.y -= visible.minY - target.minY
        } else {
            return
        }

        let inset = scroll.adjustedContentInset
        let lowest = -inset.top
        let highest = max(lowest, scroll.contentSize.height + inset.bottom - scroll.bounds.height)
        scroll.contentOffset.y = min(max(offset.y, lowest), highest)
    }

    private var enclosingScrollView: UIScrollView? {
        var candidate: UIView? = superview
        while let view = candidate {
            if let scroll = view as? UIScrollView { return scroll }
            candidate = view.superview
        }
        return nil
    }

    // MARK: Markers

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let text = attributedText ?? NSAttributedString()
        let paragraphs = paragraphRanges(in: text.string as NSString)
        let attributes = paragraphs.map { markerAttributes(for: $0, in: text) }

        drawQuoteRules(paragraphs, attributes)
        drawListMarkers(paragraphs, attributes)
    }

    // One unbroken rule per quote.
    private func drawQuoteRules(
        _ paragraphs: [NSRange],
        _ attributes: [[NSAttributedString.Key: Any]]
    ) {
        var index = 0
        while index < paragraphs.count {
            guard RichText.level(in: attributes[index]) == .quote else {
                index += 1
                continue
            }

            var last = index
            while last + 1 < paragraphs.count,
                  RichText.level(in: attributes[last + 1]) == .quote {
                last += 1
            }

            if let rule = ruleRect(from: paragraphs[index], to: paragraphs[last]) {
                inkColor.withAlphaComponent(0.3).setFill()
                UIBezierPath(roundedRect: rule, cornerRadius: rule.width / 2).fill()
            }
            index = last + 1
        }
    }

    private func ruleRect(from first: NSRange, to last: NSRange) -> CGRect? {
        let end = max(last.location, NSMaxRange(last) - 1)
        guard let start = position(from: beginningOfDocument, offset: first.location),
              let finish = position(from: beginningOfDocument, offset: end)
        else { return nil }

        let top = caretRect(for: start)
        let bottom = caretRect(for: finish)
        guard top.isFinite, !top.isNull, bottom.isFinite, !bottom.isNull else { return nil }

        let minY = min(top.minY, bottom.minY)
        let maxY = max(top.maxY, bottom.maxY)
        guard maxY > minY else { return nil }

        return CGRect(
            x: textContainerInset.left,
            y: minY,
            width: Spacing.quoteRuleWidth,
            height: maxY - minY
        )
    }

    private func drawListMarkers(
        _ paragraphs: [NSRange],
        _ attributes: [[NSAttributedString.Key: Any]]
    ) {
        var number = 0

        for (paragraph, attributes) in zip(paragraphs, attributes) {
            guard let kind = RichText.list(in: attributes) else {
                number = 0
                continue
            }

            number = kind == .numbered ? number + 1 : 0
            guard let line = lineRect(at: paragraph.location) else { continue }
            drawMarker(kind, number: number, checked: RichText.isChecked(in: attributes), on: line)
        }
    }

    // The line each paragraph starts on, in this view's own coordinates. A
    // caret rect is enough to place a drop indicator, and far cheaper than
    // asking for a full glyph pass. Null where the position cannot be resolved.
    var paragraphCarets: [CGRect] {
        let text = (attributedText?.string ?? "") as NSString
        return paragraphRanges(in: text).map { range in
            guard let spot = position(from: beginningOfDocument, offset: range.location)
            else { return .null }
            let rect = caretRect(for: spot)
            return rect.isFinite && !rect.isNull ? rect : .null
        }
    }

    private func paragraphRanges(in string: NSString) -> [NSRange] {
        var ranges: [NSRange] = []
        var index = 0
        while index < string.length {
            let paragraph = string.paragraphRange(for: NSRange(location: index, length: 0))
            ranges.append(paragraph)
            if paragraph.length == 0 { break }
            index = NSMaxRange(paragraph)
        }

        // A trailing newline opens one more paragraph that has no characters of
        // its own, and that is exactly where a new list item is being started.
        let endsOpen = string.length == 0 || string.character(at: string.length - 1) == 0x000A
        if endsOpen {
            ranges.append(NSRange(location: string.length, length: 0))
        }
        return ranges
    }

    // An empty paragraph carries no characters to hold its attributes, so what the caret is
    // about to type stands in for them.
    private func markerAttributes(
        for paragraph: NSRange,
        in text: NSAttributedString
    ) -> [NSAttributedString.Key: Any] {
        if paragraph.length > 0, paragraph.location < text.length {
            return text.attributes(at: paragraph.location, effectiveRange: nil)
        }
        return selectedRange.location == paragraph.location ? typingAttributes : [:]
    }

    private func lineRect(at location: Int) -> CGRect? {
        guard let start = position(from: beginningOfDocument, offset: location) else { return nil }

        let rect: CGRect
        if let end = position(from: start, offset: 1), let range = textRange(from: start, to: end) {
            rect = firstRect(for: range)
        } else {
            rect = caretRect(for: start)
        }
        guard rect.isFinite, !rect.isNull else { return nil }
        return rect
    }

    // A paragraph without the break that ends it.
    private func contentRange(of paragraph: NSRange, in string: NSString) -> NSRange {
        guard paragraph.length > 0 else { return paragraph }

        let last = NSMaxRange(paragraph) - 1
        let character = string.substring(with: NSRange(location: last, length: 1))
        guard character == "\n" || character == "\r" else { return paragraph }

        return NSRange(location: paragraph.location, length: paragraph.length - 1)
    }

    private func drawMarker(_ kind: TextListKind, number: Int, checked: Bool, on line: CGRect) {
        let centerY = line.minY + min(line.height, 24) / 2
        let column = CGRect(
            x: textContainerInset.left,
            y: line.minY,
            width: Spacing.listIndent - Spacing.listMarkerGap,
            height: min(line.height, 24)
        )

        switch kind {
        case .bullet:
            let size: CGFloat = 5.5
            let dot = CGRect(
                x: column.midX - size / 2,
                y: centerY - size / 2,
                width: size,
                height: size
            )
            inkColor.withAlphaComponent(0.75).setFill()
            UIBezierPath(ovalIn: dot).fill()

        case .numbered:
            let label = "\(number)." as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                .foregroundColor: inkColor.withAlphaComponent(0.65),
            ]
            let size = label.size(withAttributes: attributes)
            label.draw(
                at: CGPoint(x: column.maxX - size.width, y: centerY - size.height / 2),
                withAttributes: attributes
            )

        case .checklist:
            let side: CGFloat = 17
            let box = CGRect(
                x: column.midX - side / 2,
                y: centerY - side / 2,
                width: side,
                height: side
            )
            let path = UIBezierPath(roundedRect: box, cornerRadius: 5)

            if checked {
                inkColor.withAlphaComponent(0.8).setFill()
                path.fill()
                let tick = UIImage(
                    systemName: "checkmark",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .black)
                )?.withTintColor(fillColor, renderingMode: .alwaysOriginal)
                tick?.draw(in: box.insetBy(dx: 3.5, dy: 4))
            } else {
                inkColor.withAlphaComponent(0.4).setStroke()
                path.lineWidth = 1.8
                path.stroke()
            }
        }
    }

    // MARK: Ticking

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: self)
        guard point.x < textContainerInset.left + Spacing.listIndent else { return }
        toggleCheck(at: point)
    }

    private func toggleCheck(at point: CGPoint) {
        let string = textStorage.string as NSString
        guard string.length > 0, let position = closestPosition(to: point) else { return }

        let index = min(offset(from: beginningOfDocument, to: position), string.length - 1)
        let paragraph = string.paragraphRange(for: NSRange(location: index, length: 0))
        guard paragraph.length > 0 else { return }

        let attributes = textStorage.attributes(at: paragraph.location, effectiveRange: nil)
        guard RichText.list(in: attributes) == .checklist else { return }

        let checked = !RichText.isChecked(in: attributes)
        let selection = selectedRange

        // The tick belongs to the words, not to the break that ends them. A break carrying
        // checked is inherited by the empty paragraph Return opens next, which is how ticking
        // one item used to hand the following item a tick it never earned.
        let content = contentRange(of: paragraph, in: string)

        // Collected first: rewriting attributes while enumerating the same
        // storage is asking for trouble.
        var runs: [(NSRange, [NSAttributedString.Key: Any])] = []
        if content.length > 0 {
            textStorage.enumerateAttributes(in: content, options: []) { attributes, range, _ in
                runs.append((range, attributes))
            }
        }

        textStorage.beginEditing()
        for (range, attributes) in runs {
            textStorage.setAttributes(
                RichText.attributes(
                    level: .body,
                    bold: RichText.isBold(in: attributes),
                    italic: RichText.isItalic(in: attributes),
                    underlined: RichText.isUnderlined(in: attributes),
                    list: .checklist,
                    checked: checked,
                    ink: inkColor
                ),
                range: range
            )
        }
        // The break stays in the list so the next paragraph still reads as an item, and stays
        // unticked so that item starts out still to do.
        if content.length < paragraph.length {
            textStorage.setAttributes(
                RichText.attributes(level: .body, list: .checklist, ink: inkColor),
                range: NSRange(
                    location: NSMaxRange(content),
                    length: paragraph.length - content.length
                )
            )
        }
        textStorage.endEditing()

        selectedRange = selection
        delegate?.textViewDidChange?(self)
        setNeedsDisplay()
    }
}

extension EditorTextView: UIGestureRecognizerDelegate {
    // Shares with the text view's own tap, so a tap in the marker column both ticks the box and
    // leaves the caret where it was.
    func gestureRecognizer(
        _ recognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

private extension CGRect {
    var isFinite: Bool {
        origin.x.isFinite && origin.y.isFinite && size.width.isFinite && size.height.isFinite
    }
}
