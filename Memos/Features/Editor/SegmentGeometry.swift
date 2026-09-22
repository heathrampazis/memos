import Foundation
import SwiftUI
import UIKit

// Where each part of a note sits, and the text views behind its runs. Carrying
// a widget needs both: the frames to find what is under the finger, the views to
// find which line inside a run of writing.
@Observable
final class SegmentGeometry {
    private(set) var frames: [UUID: CGRect] = [:]

    @ObservationIgnored private var runs: [UUID: WeakTextView] = [:]

    // Written during layout, so nothing in a `body` may read `frames`: doing so
    // would register an observation and turn every frame of a drag into a
    // modify-during-update. The reads all live in gesture handling.
    func record(_ id: UUID, frame: CGRect) {
        guard frames[id] != frame else { return }
        frames[id] = frame
    }

    func register(_ id: UUID, view: EditorTextView) {
        runs[id] = WeakTextView(view)
    }

    func view(for id: UUID) -> EditorTextView? {
        runs[id]?.value
    }

    // Rebuilding the note mints new ids for its runs, so the old entries would
    // otherwise pile up for as long as the editor is open.
    func keep(_ ids: [UUID]) {
        let live = Set(ids)

        var keptFrames: [UUID: CGRect] = [:]
        for (id, frame) in frames where live.contains(id) {
            keptFrames[id] = frame
        }
        frames = keptFrames

        var keptRuns: [UUID: WeakTextView] = [:]
        for (id, run) in runs where live.contains(id) {
            keptRuns[id] = run
        }
        runs = keptRuns
    }
}

private final class WeakTextView {
    weak var value: EditorTextView?
    init(_ value: EditorTextView) { self.value = value }
}

// Reports where a segment sits, so a carried widget knows what it is passing.
struct MeasuredSegment: ViewModifier {
    let id: UUID
    let space: String
    let geometry: SegmentGeometry

    func body(content: Content) -> some View {
        content.onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named(space))
        } action: { frame in
            geometry.record(id, frame: frame)
        }
    }
}
