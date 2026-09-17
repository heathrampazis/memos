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
        view.onDeleteBackwardAtStart = { [weak coordinator] in
            coordinator?.parent.onBackspaceAtStart() ?? false
        }
        return view
    }

    func updateUIView(_ view: EditorTextView, context: Context) {
        context.coordinator.parent = self

        // Only push down when the text genuinely differs, otherwise every
        // keystroke would round-trip and fight the caret.
        if view.attributedText != text {
            let selection = view.selectedRange
            view.attributedText = text
            view.selectedRange = NSRange(
                location: min(selection.location, view.attributedText.length),
                length: 0
            )
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
        let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: max(fitted.height, Spacing.minimumTextRun))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextView

        init(_ parent: RichTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.attributedText
            parent.controller.syncState()
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
            guard parent.controller.level != .body else { return true }

            let bodyAttributes = RichText.attributes(level: .body, ink: parent.controller.inkColor)

            let storage = textView.textStorage
            storage.beginEditing()
            storage.replaceCharacters(
                in: range,
                with: NSAttributedString(string: "\n", attributes: bodyAttributes)
            )
            storage.endEditing()

            textView.selectedRange = NSRange(location: range.location + 1, length: 0)
            parent.text = textView.attributedText

            // Moving the caret makes UITextView rebuild typingAttributes from
            // the surrounding text, which lands after this method returns and
            // would overwrite anything set here. Assigning on the next pass is
            // what makes the new line take body size and weight immediately.
            DispatchQueue.main.async {
                textView.typingAttributes = bodyAttributes
                self.parent.controller.syncState()
            }
            return false
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.controller.syncState()
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
