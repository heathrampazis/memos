import Foundation
import SwiftUI

struct TileEditorView: View {
    @Bindable var tile: Tile

    @State private var controller = RichTextController()
    @State private var body_ = NSAttributedString()
    @State private var saveTask: Task<Void, Never>?
    @FocusState private var titleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Title", text: $tile.title, axis: .vertical)
                .textFieldStyle(.plain)
                .font(Typography.editorTitle)
                .foregroundStyle(Theme.ink)
                .focused($titleFocused)
                .padding(.horizontal, Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .onChange(of: tile.title) { _, new in
                    guard new.contains("\n") else { return }
                    tile.title = new.replacingOccurrences(of: "\n", with: "")
                    controller.textView?.becomeFirstResponder()
                }

            RichTextView(text: $body_, controller: controller)
                .padding(.horizontal, Spacing.screen)
        }
        .background(Theme.card)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FormatBar(controller: controller)
        }
        .onAppear(perform: load)
        .onChange(of: body_) { scheduleSave() }
        .onChange(of: tile.title) { scheduleSave() }
        .onDisappear {
            saveTask?.cancel()
            commit()
        }
    }

    private func load() {
        let restored = RichText.restore(tile.bodyData)
        body_ = restored.length == 0 ? NSAttributedString() : restored
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            commit()
        }
    }

    private func commit() {
        tile.bodyData = RichText.archive(body_)
        tile.plainText = body_.string
        tile.touch()
    }
}
