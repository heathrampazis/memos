import Foundation
import UIKit

// Colouring for a snippet, not a compiler.
enum CodeSyntax {
    // A block dark enough to be unmistakably code, and fixed rather than tinted
    // per tile: syntax colours that have to work on five tile palettes end up
    // working well on none.
    static let background = UIColor(red: 0.098, green: 0.106, blue: 0.133, alpha: 1)
    static let plain = UIColor(red: 0.894, green: 0.902, blue: 0.922, alpha: 1)
    static let gutter = UIColor(red: 0.42, green: 0.45, blue: 0.53, alpha: 1)

    private static let keyword = UIColor(red: 0.969, green: 0.549, blue: 0.612, alpha: 1)
    private static let type = UIColor(red: 0.498, green: 0.820, blue: 0.878, alpha: 1)
    private static let string = UIColor(red: 0.910, green: 0.769, blue: 0.486, alpha: 1)
    private static let number = UIColor(red: 0.718, green: 0.639, blue: 0.941, alpha: 1)
    private static let comment = UIColor(red: 0.420, green: 0.451, blue: 0.529, alpha: 1)
    private static let call = UIColor(red: 0.561, green: 0.839, blue: 0.541, alpha: 1)

    static let font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    static var paragraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        // Code wraps by character, not by word — breaking an identifier is less
        // confusing than a line that ends halfway across the block.
        style.lineBreakMode = .byCharWrapping
        style.lineSpacing = 2
        // Wrapped lines sit in a little so they read as continuations.
        style.headIndent = 14
        return style
    }

    static var baseAttributes: [NSAttributedString.Key: Any] {
        [.font: font, .foregroundColor: plain, .paragraphStyle: paragraphStyle]
    }

    // Repaints in place.
    static func highlight(_ storage: NSTextStorage, language: CodeLanguage) {
        let full = NSRange(location: 0, length: storage.length)
        guard full.length > 0 else { return }

        storage.beginEditing()
        storage.setAttributes(baseAttributes, range: full)
        for rule in compiledRules(for: language) {
            apply(rule, to: storage, in: full)
        }
        storage.endEditing()
    }

    private static func apply(_ rule: CompiledRule, to storage: NSTextStorage, in range: NSRange) {
        rule.expression.enumerateMatches(in: storage.string, options: [], range: range) { match, _, _ in
            guard let match else { return }
            let target = rule.group < match.numberOfRanges ? match.range(at: rule.group) : match.range
            guard target.location != NSNotFound else { return }
            storage.addAttribute(.foregroundColor, value: rule.color, range: target)
        }
    }

    private struct CompiledRule {
        let expression: NSRegularExpression
        let color: UIColor
        let group: Int
    }

    // Built once per language.
    private nonisolated(unsafe) static var compiled: [String: [CompiledRule]] = [:]

    private static func compiledRules(for language: CodeLanguage) -> [CompiledRule] {
        if let existing = compiled[language.rawValue] { return existing }

        let built = rules(for: language).compactMap { rule -> CompiledRule? in
            guard let expression = rule.expression else { return nil }
            return CompiledRule(expression: expression, color: rule.color, group: rule.group)
        }
        compiled[language.rawValue] = built
        return built
    }

    // MARK: Rules

    private struct Rule {
        let pattern: String
        let color: UIColor
        var group: Int = 0
        var options: NSRegularExpression.Options = []

        var expression: NSRegularExpression? {
            try? NSRegularExpression(pattern: pattern, options: options)
        }
    }

    // Order is the whole trick: later rules paint over earlier ones, so strings and comments
    // come last and a keyword inside a string stays a string.
    private static func rules(for language: CodeLanguage) -> [Rule] {
        switch language {
        case .plain:
            return []

        case .yaml:
            return [
                Rule(pattern: #"^\s*-\s"#, color: keyword, options: [.anchorsMatchLines]),
                Rule(pattern: #"^\s*([\w.\-/]+)\s*:"#, color: type, group: 1, options: [.anchorsMatchLines]),
                Rule(pattern: #"\b(true|false|null|yes|no|on|off)\b"#, color: keyword),
                Rule(pattern: #"\b-?\d[\d_]*(\.\d+)?\b"#, color: number),
                Rule(pattern: #"("(?:[^"\\]|\\.)*"|'[^']*')"#, color: string),
                Rule(pattern: #"#.*"#, color: comment),
            ]

        case .json:
            return [
                Rule(pattern: #"\b-?\d[\d_]*(\.\d+)?([eE][-+]?\d+)?\b"#, color: number),
                Rule(pattern: #"\b(true|false|null)\b"#, color: keyword),
                Rule(pattern: #""(?:[^"\\]|\\.)*""#, color: string),
                Rule(pattern: #"("(?:[^"\\]|\\.)*")\s*:"#, color: type, group: 1),
            ]

        case .html:
            return [
                Rule(pattern: #"</?([A-Za-z][\w:-]*)"#, color: keyword, group: 1),
                Rule(pattern: #"\s([A-Za-z-]+)="#, color: type, group: 1),
                Rule(pattern: #"("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')"#, color: string),
                Rule(pattern: #"<!--[\s\S]*?-->"#, color: comment),
            ]

        case .shell:
            return [
                Rule(pattern: #"\b(if|then|else|elif|fi|for|while|do|done|case|esac|function|return|export|local|in)\b"#, color: keyword),
                Rule(pattern: #"\$\{?\w+\}?"#, color: type),
                Rule(pattern: #"\b\d+\b"#, color: number),
                Rule(pattern: #"("(?:[^"\\]|\\.)*"|'[^']*')"#, color: string),
                Rule(pattern: #"#.*"#, color: comment),
            ]

        default:
            return generalRules(for: language)
        }
    }

    private static func generalRules(for language: CodeLanguage) -> [Rule] {
        var rules: [Rule] = [
            Rule(pattern: #"\b[A-Z][A-Za-z0-9_]*\b"#, color: type),
            Rule(pattern: #"\b[A-Za-z_]\w*(?=\s*\()"#, color: call),
            Rule(pattern: #"\b\d[\d_]*(\.\d+)?\b"#, color: number),
            Rule(pattern: #"\b(\#(keywords(for: language)))\b"#, color: keyword),
        ]

        if language == .swift || language == .java {
            rules.append(Rule(pattern: #"@\w+"#, color: keyword))
        }
        if language == .c {
            // Preprocessor lines read as keywords, which is close enough to how
            // they behave.
            rules.append(Rule(pattern: #"^\s*#\w+"#, color: keyword, options: [.anchorsMatchLines]))
        }
        if language == .python {
            rules.append(Rule(pattern: #"(\"\"\"[\s\S]*?\"\"\"|'''[\s\S]*?''')"#, color: string))
        }

        rules.append(Rule(pattern: #"("(?:[^"\\\n]|\\.)*"|'(?:[^'\\\n]|\\.)*')"#, color: string))
        if language == .javascript || language == .go {
            rules.append(Rule(pattern: #"`[^`]*`"#, color: string))
        }

        if language == .python {
            rules.append(Rule(pattern: #"#.*"#, color: comment))
        } else {
            rules.append(Rule(pattern: #"//.*"#, color: comment))
            rules.append(Rule(pattern: #"/\*[\s\S]*?\*/"#, color: comment))
        }
        return rules
    }

    private static func keywords(for language: CodeLanguage) -> String {
        switch language {
        case .swift:
            return "func|let|var|if|else|guard|return|for|in|while|repeat|switch|case|default|break|continue|struct|class|enum|protocol|extension|init|deinit|self|Self|nil|true|false|import|private|fileprivate|internal|public|open|static|final|lazy|weak|unowned|throws|throw|try|catch|do|defer|as|is|where|associatedtype|typealias|some|any|inout|mutating|nonisolated|await|async|actor|subscript|get|set|willSet|didSet|override|convenience|required|indirect"
        case .javascript:
            return "function|const|let|var|if|else|return|for|of|in|while|do|switch|case|default|break|continue|class|extends|new|this|super|null|undefined|true|false|import|export|from|as|async|await|try|catch|finally|throw|typeof|instanceof|delete|void|yield|static|get|set"
        case .python:
            return "def|class|if|elif|else|return|for|in|while|break|continue|pass|import|from|as|try|except|finally|raise|with|lambda|None|True|False|and|or|not|is|global|nonlocal|yield|assert|del|async|await"
        case .java:
            return "abstract|assert|boolean|break|byte|case|catch|char|class|const|continue|default|do|double|else|enum|extends|final|finally|float|for|if|implements|import|instanceof|int|interface|long|native|new|package|private|protected|public|return|short|static|strictfp|super|switch|synchronized|this|throw|throws|transient|try|void|volatile|while|var|record|sealed|permits|yield|true|false|null"
        case .go:
            return "break|case|chan|const|continue|default|defer|else|fallthrough|for|func|go|goto|if|import|interface|map|package|range|return|select|struct|switch|type|var|nil|true|false|iota|make|new|len|cap|append|copy|delete|panic|recover"
        case .c:
            return "auto|break|case|char|const|continue|default|do|double|else|enum|extern|float|for|goto|if|inline|int|long|register|restrict|return|short|signed|sizeof|static|struct|switch|typedef|union|unsigned|void|volatile|while|bool|true|false|nullptr|class|namespace|template|typename|public|private|protected|virtual|override|final|using|new|delete|this|try|catch|throw|constexpr|noexcept|static_cast|dynamic_cast|const_cast|reinterpret_cast|NULL"
        default:
            return "if|else|for|while|return|true|false|null"
        }
    }
}
