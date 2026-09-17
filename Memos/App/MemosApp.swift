import SwiftData
import SwiftUI

@main
struct MemosApp: App {
    private let container = ModelContainerFactory.make()
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(settings)
                // Deliberately no preferredColorScheme: appearance is applied
                // by the board itself, not by flipping the whole app.
                .preferredColorScheme(.light)
        }
        .modelContainer(container)
    }
}
