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
    @State private var segments: [NoteSegment] = [NoteSegment()]
    @State private var saveTask: Task<Void, Never>?
    @FocusState private var titleFocused: Bool
    @State private var isPickingColor = false
    @State private var isDeleting = false

    var body: some View {
        // Title, text and widgets all live in one scroll, so a note with a
        // recording halfway down still reads and moves as a single page.
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                titleField
                runs
                tail
            }
            .padding(.horizontal, Spacing.screen)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .overlay(alignment: .bottomTrailing) {
            AddWidgetButton(color: tileColor, onAudio: addAudioWidget)
                .padding(.trailing, Spacing.screen)
                .padding(.bottom, 16)
        }
        .background(tileColor.fill)
        .background(SwipeBackEnabler().frame(width: 0, height: 0))
        // Nothing scrolled under the bar before, so it never left its scroll-edge
        // appearance. Now it does, and the system's own material is grey glass
        // with a hairline under it. This makes the bar vanish into the note.
        .background(
            NavigationBarStyler(color: UIColor(tileColor.fill)).frame(width: 0, height: 0)
        )
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
        .onChange(of: segments) { scheduleSave() }
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

    // MARK: Layout

    private var titleField: some View {
        TextField("", text: $tile.title, axis: .vertical)
            .textFieldStyle(.plain)
            .font(Typography.editorTitle)
            .foregroundStyle(tileColor.ink)
            .focused($titleFocused)
            // Drawn by hand: a TextField prompt renders in a system grey that
            // ignores the tile's ink, and disappears on the paler neutral tiles.
            .overlay(alignment: .leading) {
                if tile.title.isEmpty {
                    Text("Title")
                        .font(Typography.editorTitle)
                        .foregroundStyle(tileColor.inkTertiary)
                        .allowsHitTesting(false)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 10)
            .onChange(of: tile.title) { _, new in
                guard new.contains("\n") else { return }
                tile.title = new.replacingOccurrences(of: "\n", with: "")
                if let first = segments.first(where: { $0.isText }) {
                    controller.focus(first.id, at: 0)
                }
            }
    }

    private var runs: some View {
        ForEach($segments) { $segment in
            if segment.clip != nil {
                AudioWidget(clip: $segment.clip.required(), color: tileColor) {
                    removeWidget(segment.id)
                }
                .padding(.vertical, 7)
            } else {
                RichTextView(
                    segmentID: segment.id,
                    text: $segment.text,
                    controller: controller,
                    onBackspaceAtStart: { mergeBack(segment.id) }
                )
            }
        }
    }

    /// Empty room under the note. Tapping it puts the caret at the end, which
    /// is what every other notes app does and what the thumb expects.
    private var tail: some View {
        Color.clear
            .frame(height: Spacing.editorTailTap)
            .contentShape(Rectangle())
            .onTapGesture(perform: focusEnd)
    }

    private var tileColor: TileColor {
        settings.color(tile.colorIndex)
    }

    // MARK: Widgets

    /// The widget takes the caret's line as the place to break the note in two:
    /// the text above stays in one run, the text below starts another, and the
    /// widget sits between them. With nothing focused it goes on the end.
    private func addAudioWidget() {
        let widget = NoteSegment(clip: AudioClip(id: UUID()))

        guard let textView = controller.textView,
              textView.isFirstResponder,
              let index = segments.firstIndex(where: { $0.id == controller.activeID }),
              segments[index].isText
        else {
            segments.append(widget)
            normalise()
            if let last = segments.last { controller.focus(last.id, at: 0) }
            return
        }

        let full = segments[index].text
        let string = full.string as NSString
        let caret = min(textView.selectedRange.location, full.length)
        let cut = full.length == 0
            ? 0
            : NSMaxRange(string.paragraphRange(for: NSRange(location: caret, length: 0)))

        let head = full.attributedSubstring(from: NSRange(location: 0, length: cut))
        let rest = full.attributedSubstring(from: NSRange(location: cut, length: full.length - cut))
        let following = NoteSegment(text: rest)

        segments[index].text = head
        segments.insert(contentsOf: [widget, following], at: index + 1)
        controller.focus(following.id, at: 0)
    }

    private func removeWidget(_ id: UUID) {
        guard let index = segments.firstIndex(where: { $0.id == id }),
              let clip = segments[index].clip
        else { return }

        AudioStore.delete(clip.id)
        withAnimation(.easeOut(duration: 0.2)) {
            segments.remove(at: index)
        }

        if index < segments.count, segments[index].isText {
            joinRuns(endingAt: segments[index].id)
        }
        normalise()
    }

    /// Backspace at the very start of a run. The widget above is taken the way
    /// a character would be; otherwise the two runs simply become one again.
    private func mergeBack(_ id: UUID) -> Bool {
        guard let index = segments.firstIndex(where: { $0.id == id }), index > 0 else {
            return false
        }

        if let clip = segments[index - 1].clip {
            AudioStore.delete(clip.id)
            segments.remove(at: index - 1)
        }

        joinRuns(endingAt: id)
        normalise()
        return true
    }

    /// Two runs of text only ever end up next to each other when the widget
    /// between them went away, so joining them is what puts the note back.
    private func joinRuns(endingAt id: UUID) {
        guard let index = segments.firstIndex(where: { $0.id == id }),
              index > 0,
              segments[index - 1].isText
        else { return }

        // Joined into the run that has the caret, not the one above it: the
        // text view keeping its place is what stops the keyboard dropping and
        // coming back on every merge.
        let previous = segments[index - 1]
        let caret = previous.text.length
        let joined = NSMutableAttributedString(attributedString: previous.text)
        joined.append(segments[index].text)

        segments[index].text = joined
        segments.remove(at: index - 1)
        controller.focus(id, at: caret)
    }

    /// A note always begins and ends with somewhere to type, or a widget at
    /// either end would leave the note with no way back into the text.
    private func normalise() {
        if segments.isEmpty { segments = [NoteSegment()] }
        if segments.first?.isText == false { segments.insert(NoteSegment(), at: 0) }
        if segments.last?.isText == false { segments.append(NoteSegment()) }
    }

    private func focusEnd() {
        guard let last = segments.last(where: { $0.isText }) else { return }
        controller.focus(last.id, at: last.text.length)
    }

    // MARK: Loading and saving

    /// The archived text has whatever ink colour it was written with baked in.
    /// Changing palette or appearance has to repaint it, or a note written on a
    /// light tile stays black on a dark one.
    private func load() {
        controller.inkColor = UIColor(tileColor.ink)
        segments = NoteCodec.repainted(NoteCodec.decode(tile.bodyData), ink: UIColor(tileColor.ink))
        normalise()
    }

    private func reload() {
        controller.inkColor = UIColor(tileColor.ink)
        segments = NoteCodec.repainted(segments, ink: UIColor(tileColor.ink))
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
        tile.bodyData = NoteCodec.encode(segments)
        tile.plainText = NoteCodec.plainText(segments)
        tile.touch()
    }

    /// Deleted on the next pass, once the pop has finished — writing to or
    /// reading a removed model mid-transition is a crash.
    private func remove() {
        let context = context
        let tile = tile
        AudioStore.deleteAll(in: segments)

        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                context.delete(tile)
            }
        }
    }

    /// A tile with no title and no content is not a tile — it goes back to
    /// being a free slot.
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
