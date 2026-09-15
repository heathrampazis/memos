import Foundation
import SwiftData

enum ModelContainerFactory {
    /// The schema is still changing shape. A model change that lightweight
    /// migration cannot handle would otherwise leave the app running against
    /// no store at all, which looks like the app is broken. In debug builds
    /// the store is discarded and rebuilt instead.
    ///
    /// Remove this once the schema settles and replace it with a versioned
    /// migration plan — at that point losing data silently is the wrong answer.
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

    /// SQLite keeps a write-ahead log and shared memory file beside the store.
    /// Leaving those behind makes the rebuilt store fail too.
    private static func deleteStore(at url: URL) {
        let directory = url.deletingLastPathComponent()
        let name = url.lastPathComponent

        for suffix in ["", "-wal", "-shm"] {
            let file = directory.appendingPathComponent(name + suffix)
            try? FileManager.default.removeItem(at: file)
        }
    }
}
