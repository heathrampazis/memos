import Foundation

/// A snippet in a note. Unlike a drawing or a photo the source is small, so it
/// rides inside the note itself rather than in a file of its own.
struct CodeBlock: Equatable, Codable {
    var id: UUID
    var language: CodeLanguage = .plain
    var code: String = ""

    var isEmpty: Bool { code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

enum CodeLanguage: String, Codable, CaseIterable, Identifiable {
    case swift, javascript, python, java, go, c, yaml, json, html, shell, plain

    var id: String { rawValue }

    var label: String {
        switch self {
        case .swift: "Swift"
        case .javascript: "JavaScript"
        case .python: "Python"
        case .java: "Java"
        case .go: "Go"
        case .c: "C / C++"
        case .yaml: "YAML"
        case .json: "JSON"
        case .html: "HTML"
        case .shell: "Shell"
        case .plain: "Plain text"
        }
    }

    /// How a line is commented out. Nil where the language has no comments
    /// worth a button.
    var comment: (open: String, close: String?)? {
        switch self {
        case .swift, .javascript, .java, .go, .c: ("//", nil)
        case .python, .shell, .yaml: ("#", nil)
        case .html: ("<!--", "-->")
        case .json, .plain: nil
        }
    }

    /// A language dropped or renamed later reads as plain text rather than
    /// failing the decode and taking the whole note with it.
    init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = CodeLanguage(rawValue: raw) ?? .plain
    }
}
