import Foundation
import SwiftUI
import SwiftData

struct TileEditorView: View {
    @Bindable var tile: Tile

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var controller = RichTextController()
    @State private var body_ = NSAttributedString()
    @State private var saveTask: Task<Void, Never>?
    @FocusState private var titleFocused: Bool
    @State private var isPickingColor = false

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
        .background(tileColor.fill)
        .background(SwipeBackEnabler().frame(width: 0, height: 0))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CircleIconButton(systemImage: "chevron.left") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                CircleIconButton(systemImage: "ellipsis") {
                    isPickingColor = true
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FormatBar(controller: controller, color: tileColor)
        }
        .sheet(isPresented: $isPickingColor) {
            TileColorPicker(selection: $tile.colorIndex)
        }
        .onAppear(perform: load)
        .onChange(of: body_) { scheduleSave() }
        .onChange(of: tile.title) { scheduleSave() }
        .onChange(of: tile.colorIndex) { tile.touch() }
        .onDisappear {
            saveTask?.cancel()
            commit()
            discardIfBlank()
        }
    }

    private var tileColor: TileColor {
        TilePalette.color(tile.colorIndex)
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

    /// A tile with no title and no text is not a tile — it goes back to being
    /// a free slot. Deleting on the next pass lets the pop finish first, so
    /// nothing is reading the model while it is being removed.
    private func discardIfBlank() {
        guard tile.isBlank else { return }
        let context = context
        let tile = tile

        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                context.delete(tile)
            }
        }
    }
}
