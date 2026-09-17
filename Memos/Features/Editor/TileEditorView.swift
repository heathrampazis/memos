import Foundation
import SwiftUI
import UIKit
import SwiftData

struct TileEditorView: View {
    @Bindable var tile: Tile

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings

    @State private var controller = RichTextController()
    @State private var body_ = NSAttributedString()
    @State private var saveTask: Task<Void, Never>?
    @FocusState private var titleFocused: Bool
    @State private var isPickingColor = false
    @State private var isDeleting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("", text: $tile.title, axis: .vertical)
                .textFieldStyle(.plain)
                .font(Typography.editorTitle)
                .foregroundStyle(tileColor.ink)
                .focused($titleFocused)
                // Drawn by hand: a TextField prompt renders in a system grey
                // that ignores the tile's ink, and disappears on the paler
                // neutral tiles.
                .overlay(alignment: .leading) {
                    if tile.title.isEmpty {
                        Text("Title")
                            .font(Typography.editorTitle)
                            .foregroundStyle(tileColor.inkTertiary)
                            .allowsHitTesting(false)
                    }
                }
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
        // Sits inside the safe area inset, so it floats clear of the format
        // tray rather than over it.
        .overlay(alignment: .bottomTrailing) {
            AddWidgetButton(color: tileColor) {
                // Choosing and inserting a widget is its own ticket.
            }
            .padding(.trailing, Spacing.screen)
            .padding(.bottom, 16)
        }
        .background(tileColor.fill)
        .background(SwipeBackEnabler().frame(width: 0, height: 0))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CircleIconButton(systemImage: "chevron.left", tint: tileColor.ink) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                CircleIconButton(systemImage: "ellipsis", tint: tileColor.ink) {
                    isPickingColor = true
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FormatBar(controller: controller, color: tileColor)
        }
        .sheet(isPresented: $isPickingColor) {
            TileColorPicker(selection: $tile.colorIndex) {
                isDeleting = true
                isPickingColor = false
                dismiss()
            }
        }
        .onAppear(perform: load)
        .onChange(of: tile.colorIndex) { reload() }
        .onChange(of: settings.palette) { reload() }
        .onChange(of: body_) { scheduleSave() }
        .onChange(of: tile.title) { scheduleSave() }
        .onChange(of: tile.colorIndex) { tile.touch() }
        .onDisappear {
            saveTask?.cancel()
            guard !isDeleting else {
                remove()
                return
            }
            commit()
            discardIfBlank()
        }
    }

    private var tileColor: TileColor {
        settings.color(tile.colorIndex)
    }

    /// The archived text has whatever ink colour it was written with baked in.
    /// Changing palette or appearance has to repaint it, or a note written on a
    /// light tile stays black on a dark one.
    private func load() {
        let restored = RichText.restore(tile.bodyData)
        body_ = RichText.repainted(restored, ink: UIColor(tileColor.ink))
        controller.inkColor = UIColor(tileColor.ink)
    }

    private func reload() {
        controller.inkColor = UIColor(tileColor.ink)
        body_ = RichText.repainted(body_, ink: UIColor(tileColor.ink))
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

    /// Deleted on the next pass, once the pop has finished — writing to or
    /// reading a removed model mid-transition is a crash.
    private func remove() {
        let context = context
        let tile = tile
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                context.delete(tile)
            }
        }
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
