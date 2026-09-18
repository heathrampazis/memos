import Foundation
import SwiftData

enum ModelContainerFactory {
    // The schema is still changing shape, so in debug builds a store that cannot
    // be migrated is discarded and rebuilt rather than leaving the app running
    // against nothing. Replace this with a versioned migration plan before real
    // notes depend on it — losing data silently is the wrong answer by then.
    static func make() -> ModelContainer {
        let schema = Schema([Tile.self])
        let configuration = ModelConfiguration(schema: schema)

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            #if DEBUG
            print("SwiftData store could not be opened, rebuilding it: \(error)")
            deleteStore(at: configuration.url)
            do {
                return try ModelContainer(for: schema, configurations: configuration)
            } catch {
                fatalError("Rebuilding the store failed: \(error)")
            }
            #else
            fatalError("Could not open the SwiftData store: \(error)")
            #endif
        }
    }

    // SQLite keeps a write-ahead log and shared memory file beside the store.
    private static func deleteStore(at url: URL) {
        let directory = url.deletingLastPathComponent()
        let name = url.lastPathComponent

        for suffix in ["", "-wal", "-shm"] {
            let file = directory.appendingPathComponent(name + suffix)
            try? FileManager.default.removeItem(at: file)
        }
    }
}
