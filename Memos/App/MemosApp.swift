import SwiftData
import SwiftUI

@main
struct MemosApp: App {
    var body: some Scene {
        WindowGroup {
            BoardView()
        }
        .modelContainer(for: Memo.self)
    }
}
