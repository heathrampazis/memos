import Foundation
import SwiftUI
import UIKit

// The editable part of a code block.
struct CodeEditorView: UIViewRepresentable {
    let blockID: UUID
    @Binding var code: String
    let language: CodeLanguage
    let session: CodeSession

    func makeUIView(context: Context) -> CodeTextView {
        let view = CodeTextView()
        view.delegate = context.coordinator
        view.language = language
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0

        view.autocorrectionType = .no
        view.autocapitalizationType = .none
        view.smartQuotesType = .no
        view.smartDashesType = .no
        view.smartInsertDeleteType = .no
        view.spellCheckingType = .no
        view.keyboardType = .asciiCapable

        view.tintColor = CodeSyntax.plain
        view.typingAttributes = CodeSyntax.baseAttributes
        view.text = code

        CodeSyntax.highlight(view.textStorage, language: language)
        context.coordinator.appliedLanguage = language
        return view
    }

    func updateUIView(_ view: CodeTextView, context: Context) {
        context.coordinator.parent = self
        view.language = language
        session.refresh(view)

        var needsHighlight = false

        if view.text != code {
            let selection = view.selectedRange
            view.text = code
            view.selectedRange = NSRange(
                location: min(selection.location, (view.text as NSString).length),
                length: 0
            )
            needsHighlight = true
            context.coordinator.isStale = true
        }

        if context.coordinator.appliedLanguage != language {
            context.coordinator.appliedLanguage = language
            needsHighlight = true
        }

        guard needsHighlight else { return }
        let selection = view.selectedRange
        CodeSyntax.highlight(view.textStorage, language: language)
        view.selectedRange = selection
        view.typingAttributes = CodeSyntax.baseAttributes
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: CodeTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0, width.isFinite else { return nil }
        let coordinator = context.coordinator

        // Cached for the same reason the note's text runs are: a drag on a
        // widget elsewhere re-measures everything, every frame.
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
        var parent: CodeEditorView
        var appliedLanguage: CodeLanguage = .plain

        var measuredWidth: CGFloat = 0
        var measuredHeight: CGFloat = 0
        var isStale = true

        init(_ parent: CodeEditorView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.code = textView.text
            isStale = true

            let selection = textView.selectedRange
            CodeSyntax.highlight(textView.textStorage, language: parent.language)
            textView.selectedRange = selection
            textView.typingAttributes = CodeSyntax.baseAttributes
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            guard let view = textView as? CodeTextView else { return }
            parent.session.activate(view, id: parent.blockID)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            guard let view = textView as? CodeTextView else { return }
            DispatchQueue.main.async {
                self.parent.session.deactivate(view)
            }
        }
    }
}
