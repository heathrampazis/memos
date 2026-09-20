import SwiftUI

// From iOS 26 the system gives every toolbar item its own Liquid Glass capsule and sizes the
// item to that capsule's metrics. Buttons that already draw their own background come out
// doubled up and squeezed, so they opt out and keep drawing themselves.
//
// The app still deploys to iOS 18, where the modifier does not exist and there is no glass
// to turn off, so the call is guarded.
extension ToolbarContent {
    @ToolbarContentBuilder
    func plainBackground() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            self.sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}
