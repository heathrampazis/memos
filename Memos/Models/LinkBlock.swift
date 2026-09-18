import Foundation

/// A bookmark in a note. The page's own title and picture are fetched once and
/// kept, so a note opened offline still reads as a bookmark rather than a URL.
struct LinkBlock: Equatable, Codable {
    var id: UUID
    var url: String
    var title: String = ""

    /// Whether the fetch has been attempted, successfully or not. Without it a
    /// page with no title would be looked up every time the note opened.
    var fetched: Bool = false
    var hasImage: Bool = false
    var revision: Int = 0

    var isEmpty: Bool { url.isEmpty }

    /// What the card shows under the title, and all it shows when the fetch
    /// came back with nothing.
    var host: String {
        guard let host = URL(string: url)?.host() else { return url }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    var displayTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? host : title
    }
}
