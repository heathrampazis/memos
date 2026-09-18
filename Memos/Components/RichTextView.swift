import Foundation
import SwiftUI
import UIKit

/// One run of text in a note. It does not scroll — the page does — so it sizes
/// itself to its content and the widgets above and below it sit in the same
/// scroll as ordinary lines.
struct RichTextView: UIViewRepresentable {
    let segmentID: UUID
    @Binding var text: NSAttributedString
    let controller: RichTextController

    /// Backspace at the very start. Returns true when the editor handled it.
    var onBackspaceAtStart: () -> Bool

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
        view.onDeleteBackwardAtStart = { [weak coordinator] in
            coordinator?.parent.onBackspaceAtStart() ?? false
        }
        view.onDeleteBackwardAtParagraphStart = { [weak coordinator, weak view] in
            guard let controller = coordinator?.parent.controller, let view else { return false }
            // Backspace at the head of a list item takes it out of the list
            // before it starts eating the line above.
            guard controller.list != nil, controller.isAtParagraphStart(in: view) else { return false }
            controller.clearList()
            return true
        }
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

        /// Everything that changes the text goes through here, so the cached
        /// height is invalidated in exactly one place.
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
            (textView as? EditorTextView)?.revealCaret()
        }

        /// A new line after a title or heading carries on as body text.
        ///
        /// The line break itself is given body attributes, not the heading's.
        /// UITextView rebuilds typingAttributes from the character before the
        /// caret whenever the selection moves, so a break that carried heading
        /// attributes would immediately undo this.
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
                if controller.isListItemEmpty(in: textView) {
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

            guard controller.level != .body else { return true }

            let bodyAttributes = RichText.attributes(level: .body, ink: controller.inkColor)

            return continueParagraph(in: textView, at: range, with: bodyAttributes)
        }

        /// Inserts the line break itself carrying the attributes the next line
        /// should have. UITextView rebuilds typingAttributes from the character
        /// before the caret whenever the selection moves, so a break that
        /// carried the old attributes would immediately undo this.
        private func continueParagraph(
            in textView: UITextView,
            at range: NSRange,
            with attributes: [NSAttributedString.Key: Any]
        ) -> Bool {
            let storage = textView.textStorage
            storage.beginEditing()
            storage.replaceCharacters(
                in: range,
                with: NSAttributedString(string: "\n", attributes: attributes)
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
