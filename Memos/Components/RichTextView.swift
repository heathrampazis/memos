import Foundation
import SwiftUI
import UIKit

// One run of text in a note.
struct RichTextView: UIViewRepresentable {
    let segmentID: UUID
    @Binding var text: NSAttributedString
    let controller: RichTextController

    // Backspace at the very start.
    var onBackspaceAtStart: () -> Bool

    // A word was just finished, which is when a URL on its own line becomes a bookmark.
    var onWordCommitted: () -> Void

    // Handed the text view once it exists, so a carried widget can ask which
    // line of this run it is hovering over.
    var onView: (EditorTextView) -> Void

    func makeUIView(context: Context) -> EditorTextView {
        let view = EditorTextView()
        let coordinator = context.coordinator

        view.delegate = coordinator
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.keyboardDismissMode = .interactive
        view.attributedText = text
        view.typingAttributes = RichText.attributes(level: .body, ink: controller.inkColor)
        view.inkColor = controller.inkColor
        view.fillColor = controller.fillColor
        view.onWordCommitted = { [weak coordinator] in
            coordinator?.parent.onWordCommitted()
        }
        view.onDeleteBackwardAtStart = { [weak coordinator] in
            coordinator?.parent.onBackspaceAtStart() ?? false
        }
        view.onDeleteBackwardAtParagraphStart = { [weak coordinator, weak view] in
            guard let controller = coordinator?.parent.controller, let view else { return false }
            // Backspace at the head of a list item takes it out of the list
            // before it starts eating the line above.
            guard controller.isAtParagraphStart(in: view) else { return false }

            if controller.list != nil {
                controller.clearList()
                return true
            }
            // Backspace at the head of a quote leaves the quote before it
            // starts eating the line above.
            if controller.level == .quote {
                controller.apply(level: .body)
                return true
            }
            return false
        }
        onView(view)
        return view
    }

    func updateUIView(_ view: EditorTextView, context: Context) {
        context.coordinator.parent = self
        view.inkColor = controller.inkColor
        view.fillColor = controller.fillColor

        // Only push down when the text genuinely differs, otherwise every
        // keystroke would round-trip and fight the caret.
        if view.attributedText != text {
            let selection = view.selectedRange
            view.attributedText = text
            view.selectedRange = NSRange(
                location: min(selection.location, view.attributedText.length),
                length: 0
            )
            context.coordinator.isStale = true
        }

        guard controller.focusRequest?.segmentID == segmentID else { return }
        // Claiming the responder mid-update fights the layout pass that put the
        // run here in the first place, so it waits for the next one.
        DispatchQueue.main.async {
            guard let request = controller.focusRequest, request.segmentID == segmentID else { return }
            controller.focusRequest = nil
            view.becomeFirstResponder()
            view.selectedRange = NSRange(
                location: min(request.location, view.attributedText.length),
                length: 0
            )
            view.revealCaret()
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: EditorTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0, width.isFinite else { return nil }
        let coordinator = context.coordinator

        // Laying the run out again is the expensive part, and a widget elsewhere
        // in the note changing height asks every run to measure on every frame
        // of the drag. Nothing about this run has changed, so the last answer
        // still holds.
        if !coordinator.isStale, coordinator.measuredWidth == width {
            return CGSize(width: width, height: coordinator.measuredHeight)
        }

        let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        coordinator.measuredWidth = width
        coordinator.measuredHeight = max(fitted.height, Spacing.minimumTextRun)
        coordinator.isStale = false
        return CGSize(width: width, height: coordinator.measuredHeight)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextView

        var measuredWidth: CGFloat = 0
        var measuredHeight: CGFloat = 0
        var isStale = true

        init(_ parent: RichTextView) {
            self.parent = parent
        }

        // Everything that changes the text goes through here, so the cached height is
        // invalidated in exactly one place.
        func publish(_ textView: UITextView) {
            parent.text = textView.attributedText
            isStale = true
        }

        func textViewDidChange(_ textView: UITextView) {
            publish(textView)
            parent.controller.syncState()
            // Markers are painted on, so they are only right once the text they
            // sit beside has been laid out again.
            textView.setNeedsDisplay()

            // Next pass, not this one: publishing the text is what resizes the
            // run, and chasing the caret before that lands aims at where it
            // used to be. It costs nothing to wait — the reveal does nothing at
            // all unless the caret has actually gone out of view.
            DispatchQueue.main.async {
                (textView as? EditorTextView)?.revealCaret()
            }
        }

        // A new line after a title or heading carries on as body text.
        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText replacement: String
        ) -> Bool {
            guard replacement == "\n" else { return true }
            let controller = parent.controller

            if controller.list != nil {
                // Return on an item with nothing in it ends the list, the way
                // it does everywhere else. Otherwise the next line is an item.
                if controller.isParagraphEmpty(in: textView) {
                    controller.clearList()
                    return false
                }
                return continueParagraph(
                    in: textView,
                    at: range,
                    with: RichText.attributes(
                        level: .body, list: controller.list, ink: controller.inkColor
                    )
                )
            }

            // A quote runs on the way a list does: another line stays in it, and
            // an empty line leaves it.
            if controller.level == .quote {
                if controller.isLineEmpty(in: textView) {
                    return leaveQuote(textView, at: range)
                }
                // A soft break rather than a paragraph break, so the whole
                // quote stays one paragraph. Two paragraphs would stack the
                // space below one against the space above the next, and the
                // air meant to sit around the block would open up inside it.
                return continueParagraph(
                    in: textView,
                    at: range,
                    with: RichText.attributes(level: .quote, ink: controller.inkColor),
                    separator: "\u{2028}"
                )
            }

            guard controller.level != .body else { return true }

            let bodyAttributes = RichText.attributes(level: .body, ink: controller.inkColor)

            return continueParagraph(in: textView, at: range, with: bodyAttributes)
        }

        // Inserts the line break itself carrying the attributes the next line should have.
        private func continueParagraph(
            in textView: UITextView,
            at range: NSRange,
            with attributes: [NSAttributedString.Key: Any],
            separator: String = "\n"
        ) -> Bool {
            let storage = textView.textStorage
            storage.beginEditing()
            storage.replaceCharacters(
                in: range,
                with: NSAttributedString(string: separator, attributes: attributes)
            )
            storage.endEditing()

            textView.selectedRange = NSRange(location: range.location + 1, length: 0)
            publish(textView)
            textView.setNeedsDisplay()

            // Moving the caret makes UITextView rebuild typingAttributes, which
            // lands after this method returns and would overwrite anything set
            // here. Assigning on the next pass is what makes the new line take
            // the right size, weight and marker immediately.
            DispatchQueue.main.async {
                textView.typingAttributes = attributes
                self.parent.controller.syncState()
                textView.setNeedsDisplay()
            }
            return false
        }

        // Return on an empty line inside a quote ends it.
        private func leaveQuote(_ textView: UITextView, at range: NSRange) -> Bool {
            let source = textView.text as NSString
            let body = RichText.attributes(level: .body, ink: parent.controller.inkColor)

            var replaced = range
            if range.location > 0,
               source.substring(with: NSRange(location: range.location - 1, length: 1)) == "\u{2028}" {
                replaced = NSRange(location: range.location - 1, length: range.length + 1)
            }

            let storage = textView.textStorage
            storage.beginEditing()
            storage.replaceCharacters(
                in: replaced,
                with: NSAttributedString(string: "\n", attributes: body)
            )
            storage.endEditing()

            textView.selectedRange = NSRange(location: replaced.location + 1, length: 0)
            publish(textView)
            textView.setNeedsDisplay()

            DispatchQueue.main.async {
                textView.typingAttributes = body

                // Applied rather than inferred. An empty last line takes its
                // shape from the paragraph above it, so leaving it to be read
                // back left the new line wearing the quote's indent. This says
                // it outright — and where the quote had text after the caret,
                // that text becomes body too, which is what leaving a quote
                // means.
                self.parent.controller.apply(level: .body)
                textView.setNeedsDisplay()
            }
            return false
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.controller.syncState()
            // The caret moving is what tells an empty paragraph whether its
            // marker should be there, so the gutter is repainted with it.
            textView.setNeedsDisplay()
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.controller.activate(textView, segmentID: parent.segmentID)
            // The keyboard's inset lands a beat after this, so the caret is
            // only worth chasing once it has.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                (textView as? EditorTextView)?.revealCaret()
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            // Moving between runs ends one and begins the next, so this waits to
            // see whether another run picked the caret up.
            DispatchQueue.main.async {
                self.parent.controller.deactivate(textView)
            }
        }
    }
}
