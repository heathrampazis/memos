import Foundation

// Finds a URL that is sitting alone on its own line.
enum LinkDetector {
    private static let detector = try? NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue
    )

    // The paragraph to replace, and what it points at.
    static func standaloneLink(in text: NSString, near caret: Int) -> (range: NSRange, url: URL)? {
        guard text.length > 0 else { return nil }

        // One back from the caret: the space or newline that committed the word
        // still belongs to the line the URL is on.
        let probe = min(max(caret - 1, 0), text.length - 1)
        let paragraph = text.paragraphRange(for: NSRange(location: probe, length: 0))

        let line = text.substring(with: paragraph).trimmingCharacters(in: .whitespacesAndNewlines)
        guard line.count > 6, !line.contains(" ") else { return nil }

        let whole = NSRange(location: 0, length: (line as NSString).length)
        guard let match = detector?.firstMatch(in: line, options: [], range: whole),
              match.range == whole,
              let url = match.url,
              let scheme = url.scheme,
              scheme == "http" || scheme == "https"
        else { return nil }

        return (paragraph, url)
    }
}
