import Foundation
import SwiftUI
import UIKit

/// One UITextView for the whole note. One first responder, so the keyboard
/// never flickers, held keys keep repeating, and scrolling to the caret is
/// UIKit's job rather than ours.
struct RichTextView: UIViewRepresentable {
    @Binding var text: NSAttributedString
    let controller: RichTextController

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.textContainerInset = UIEdgeInsets(
            top: 4, left: 0, bottom: Spacing.editorTrailingSpace, right: 0
        )
        view.textContainer.lineFragmentPadding = 0
        view.alwaysBounceVertical = true
        view.keyboardDismissMode = .interactive
        view.attributedText = text
        view.typingAttributes = RichText.attributes(level: .body)

        controller.textView = view
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.parent = self

        // Only push down when the text genuinely differs, otherwise every
        // keystroke would round-trip and fight the caret.
        if view.attributedText != text {
            let selection = view.selectedRange
            view.attributedText = text
            view.selectedRange = selection
        }
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

            let bodyAttributes = RichText.attributes(level: .body)

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
            parent.controller.syncState()
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.controller.syncState()
        }
    }
}
