import SwiftData
import SwiftUI

@main
struct MemosApp: App {
    private let container = ModelContainerFactory.make()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.light)
        }
        .modelContainer(container)
    }
}
