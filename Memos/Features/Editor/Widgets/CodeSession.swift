import Foundation
import SwiftUI
import UIKit

/// Which code block has the caret, so the tray can type into it.
///
/// The symbol row needs to reach the text view being edited, and the tray has
/// no way to know which card that is — the card tells this, and the tray asks
/// it. All the behaviour lives in the text view; this only forwards.
@Observable
final class CodeSession {
    private(set) var activeID: UUID?
    private(set) var language: CodeLanguage = .plain

    @ObservationIgnored weak var textView: CodeTextView?

    func activate(_ textView: CodeTextView, id: UUID) {
        self.textView = textView
        activeID = id
        language = textView.language
    }

    /// The kind can change under the caret from the card's own menu, and the
    /// tray's comment button has to follow it.
    func refresh(_ textView: CodeTextView) {
        guard self.textView === textView else { return }
        language = textView.language
    }

    func deactivate(_ textView: CodeTextView) {
        guard self.textView === textView else { return }
        activeID = nil
    }

    private var active: CodeTextView? {
        guard let textView, textView.isFirstResponder else { return nil }
        return textView
    }

    /// Goes through insertText, so a bracket typed from the row auto-closes
    /// exactly as one typed on the keyboard does.
    func insert(_ text: String) { active?.insertText(text) }

    func indent() { active?.indentLine() }
    func outdent() { active?.outdentLine() }
    func toggleComment() { active?.toggleComment() }

    var commentToken: String? {
        language.comment?.open
    }
}
