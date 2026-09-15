import SwiftData
import SwiftUI

@main
struct MemosApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: Tile.self)
    }
}
