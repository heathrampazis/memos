import Foundation

// Widgets that keep a file on disk, cleaned up in one place. Listing the stores
// by hand at every call site is how bookmark thumbnails were left behind when a
// tile was deleted.
enum WidgetStore {
    static func delete(_ segment: TileSegment) {
        if let clip = segment.clip { AudioStore.delete(clip.id) }
        if let drawing = segment.drawing { DrawingStore.delete(drawing.id) }
        if let photo = segment.photo { PhotoStore.delete(photo.id) }
        if let link = segment.link { LinkStore.delete(link.id) }
    }

    static func deleteAll(in segments: [TileSegment]) {
        for segment in segments {
            delete(segment)
        }
    }
}
