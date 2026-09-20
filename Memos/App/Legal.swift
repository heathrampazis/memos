import Foundation

// The links App Review expects to be reachable from inside the app, and the
// version string that belongs with a bug report.
enum Legal {
    static let privacyPolicy = URL(string: "https://heathrampazis.github.io/memos/privacy.html")!
    static let support = URL(string: "https://heathrampazis.github.io/memos/")!

    // Apple's standard licence agreement, which covers every app that does not
    // supply terms of its own.
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "Memos \(short) (\(build))"
    }
}
