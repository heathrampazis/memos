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
    @State private var segments: [TileSegment] = [TileSegment()]
    @State private var saveTask: Task<Void, Never>?
    @FocusState private var titleFocused: Bool
    @State private var isPickingColor = false
    @State private var isDeleting = false
    @State private var isEditingWidgets = false
    @State private var pendingWidget: UUID?
    @State private var isConfirmingWidget = false
    @State private var isInserting = false
    @State private var focusedPanel: UUID?
    @State private var codeSession = CodeSession()
    @State private var focusedTable: TableFocus?

    private struct TableFocus: Equatable {
        let id: UUID
        var cell: TableCell
    }

    // Where a widget will land, taken the moment the (+) is pressed.
    @State private var insertionPoint: SegmentInsertion?

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
        .overlay(alignment: .bottomTrailing) {
            AddWidgetButton(color: tileColor, isOpen: isInserting) {
                if isInserting {
                    stopInserting()
                } else {
                    beginInserting()
                }
            }
            .padding(.trailing, Spacing.screen)
            .padding(.bottom, 16)
        }
        // Nothing to format means no bar: an empty strip claiming you are
        // editing was the whole complaint about the old one.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if trayMode != .idle {
                EditorTray(
                    controller: controller,
                    color: tileColor,
                    mode: trayMode,
                    panelKind: focusedPanelKind,
                    onPanelKind: setPanelKind,
                    onChoose: add,
                    codeSession: codeSession,
                    onTable: applyTable
                )
            }
        }
        .sheet(isPresented: $isPickingColor) {
            TileColorPicker(selection: $tile.colorIndex) {
                isDeleting = true
                isPickingColor = false
                dismiss()
            }
        }
        .confirmationDialog(
            "Delete this \(pendingWidgetName)?",
            isPresented: $isConfirmingWidget,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let id = pendingWidget { removeWidget(id) }
                pendingWidget = nil
            }
            Button("Cancel", role: .cancel) { pendingWidget = nil }
        } message: {
            Text("It will be removed from the note.")
        }
        .onAppear(perform: load)
        .onChange(of: tile.colorIndex) { reload() }
        .onChange(of: settings.palette) { reload() }
        .onChange(of: segments) { scheduleSave() }
        // Typing again is the clearest sign the note is being written, not
        // rearranged.
        .onChange(of: controller.isEditing) { _, editing in
            guard editing else { return }
            stopEditingWidgets()
            stopInserting()
        }
        .onChange(of: codeSession.activeID) { _, active in
            guard active != nil else { return }
            stopEditingWidgets()
            stopInserting()
        }
        .onChange(of: activeTable) { _, active in
            guard active != nil else { return }
            stopEditingWidgets()
            stopInserting()
        }
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
                AudioWidget(clip: $segment.clip.required(), color: tileColor)
                    .modifier(deletable(segment.id))
                    .padding(.vertical, 7)
            } else if segment.panel != nil {
                PanelWidget(panel: $segment.panel.required(), color: tileColor) { isFocused in
                    trackPanelFocus(segment.id, isFocused)
                }
                .modifier(deletable(segment.id))
                    .padding(.vertical, 7)
            } else if segment.drawing != nil {
                DrawingWidget(block: $segment.drawing.required(), color: tileColor)
                    .modifier(deletable(segment.id))
                    .padding(.vertical, 7)
            } else if segment.photo != nil {
                PhotoWidget(photo: $segment.photo.required(), color: tileColor)
                    .modifier(deletable(segment.id))
                    .padding(.vertical, 7)
            } else if segment.link != nil {
                LinkWidget(link: $segment.link.required(), color: tileColor)
                    .modifier(deletable(segment.id))
                    .padding(.vertical, 7)
            } else if segment.table != nil {
                TableWidget(
                    block: $segment.table.required(),
                    focus: tableFocus(for: segment.id),
                    color: tileColor
                )
                .modifier(deletable(segment.id))
                .padding(.vertical, 7)
            } else if segment.code != nil {
                CodeWidget(
                    block: $segment.code.required(),
                    color: tileColor,
                    session: codeSession
                )
                .modifier(deletable(segment.id))
                .padding(.vertical, 7)
            } else {
                RichTextView(
                    segmentID: segment.id,
                    text: $segment.text,
                    controller: controller,
                    onBackspaceAtStart: { mergeBack(segment.id) },
                    onWordCommitted: detectLink
                )
            }
        }
    }

    // Every widget wears the same delete affordance, so the wiring is written once here rather
    // than three times in the cards.
    private func deletable(_ id: UUID) -> DeletableWidget {
        DeletableWidget(
            isEditing: isEditingWidgets,
            color: tileColor,
            seed: seed(for: id),
            onHold: holdWidgets,
            onDismiss: stopEditingWidgets,
            onDelete: { confirmRemove(id) }
        )
    }

    // Enough to give each widget its own wobble period so they do not swing in lockstep.
    private func seed(for id: UUID) -> Int {
        Int(id.uuid.0)
    }

    // Empty room under the note.
    private var tail: some View {
        Color.clear
            .frame(height: Spacing.editorTailTap)
            .contentShape(Rectangle())
            .onTapGesture(perform: focusEnd)
    }

    private var tileColor: TileColor {
        settings.color(tile.colorIndex)
    }

    // MARK: The tray

    // A panel's own text field wins over the note's, because the caret really is inside it —
    // the run of text behind it just has not been told yet.
    private var trayMode: EditorTrayMode {
        if isInserting { return .insert }
        if codeSession.activeID != nil { return .code }
        if activeTable != nil { return .table }
        if focusedPanelKind != nil { return .panel }
        if titleFocused { return .title }
        if controller.isEditing { return .text }
        return .idle
    }

    private var focusedPanelKind: PanelKind? {
        guard let id = focusedPanel else { return nil }
        return segments.first(where: { $0.id == id })?.panel?.kind
    }

    private func trackPanelFocus(_ id: UUID, _ isFocused: Bool) {
        if isFocused {
            focusedPanel = id
        } else if focusedPanel == id {
            focusedPanel = nil
        }
    }

    // A table that is still in the note.
    private var activeTable: TableFocus? {
        guard let focus = focusedTable,
              segments.contains(where: { $0.id == focus.id && $0.table != nil })
        else { return nil }
        return focus
    }

    // One table is focused at a time, so the editor keeps the cell rather than each card
    // keeping its own and the tray having to ask around.
    private func tableFocus(for id: UUID) -> Binding<TableCell?> {
        Binding(
            get: { focusedTable?.id == id ? focusedTable?.cell : nil },
            set: { cell in
                if let cell {
                    focusedTable = TableFocus(id: id, cell: cell)
                } else if focusedTable?.id == id {
                    focusedTable = nil
                }
            }
        )
    }

    // Every action is relative to the focused cell, and a move takes the caret with it so the
    // same row can be nudged twice without hunting for it.
    private func applyTable(_ action: TableAction) {
        guard let focus = activeTable,
              let index = segments.firstIndex(where: { $0.id == focus.id }),
              var table = segments[index].table
        else { return }

        var cell = focus.cell

        switch action {
        case .addRow:
            table.addRow(after: cell.row)
            cell.row = min(cell.row + 1, table.rowCount - 1)
        case .deleteRow:
            table.removeRow(cell.row)
            cell.row = min(cell.row, table.rowCount - 1)
        case .moveRowUp:
            table.moveRow(cell.row, by: -1)
            cell.row = max(1, cell.row - 1)
        case .moveRowDown:
            table.moveRow(cell.row, by: 1)
            cell.row = min(cell.row + 1, table.rowCount - 1)
        case .addColumn:
            table.addColumn(after: cell.column)
            cell.column = min(cell.column + 1, table.columnCount - 1)
        case .deleteColumn:
            table.removeColumn(cell.column)
            cell.column = min(cell.column, table.columnCount - 1)
        case .moveColumnLeft:
            table.moveColumn(cell.column, by: -1)
            cell.column = max(0, cell.column - 1)
        case .moveColumnRight:
            table.moveColumn(cell.column, by: 1)
            cell.column = min(cell.column + 1, table.columnCount - 1)
        }

        withAnimation(.easeOut(duration: 0.16)) {
            segments[index].table = table
        }
        focusedTable = TableFocus(id: focus.id, cell: cell)
    }

    private func setPanelKind(_ kind: PanelKind) {
        guard let id = focusedPanel,
              let index = segments.firstIndex(where: { $0.id == id })
        else { return }
        segments[index].panel?.kind = kind
    }

    private func beginInserting() {
        // Captured before the keyboard goes, while the text view still knows
        // where the caret is.
        if controller.isEditing, let id = controller.activeID, let view = controller.textView {
            insertionPoint = SegmentInsertion(segmentID: id, location: view.selectedRange.location)
        } else {
            insertionPoint = nil
        }
        controller.endEditing()
        stopEditingWidgets()
        withAnimation(.easeOut(duration: 0.2)) { isInserting = true }
    }

    private func stopInserting() {
        withAnimation(.easeOut(duration: 0.2)) { isInserting = false }
    }

    private func add(_ choice: WidgetChoice) {
        stopInserting()
        switch choice {
        case .photo: addPhoto()
        case .drawing: addDrawing()
        case .voice: addAudioWidget()
        case .code: addCode()
        case .table: addTable()
        case .panel(let kind): addPanel(kind)
        }
    }

    // MARK: Widgets

    private func addAudioWidget() {
        // The caret moves below the card, ready to keep writing; recording is
        // the card's own button, so nothing here starts it.
        insert(TileSegment(clip: AudioClip(id: UUID())), thenType: true)
    }

    private func addPanel(_ kind: PanelKind) {
        // A panel is inserted empty and takes the caret itself, so the keyboard
        // stays up and lands in the box that was just made.
        insert(TileSegment(panel: PanelBlock(id: UUID(), kind: kind)), thenType: false)
    }

    private func addDrawing() {
        insert(TileSegment(drawing: DrawingBlock(id: UUID())), thenType: false)
    }

    private func addPhoto() {
        insert(TileSegment(photo: PhotoBlock(id: UUID())), thenType: false)
    }

    private func addCode() {
        insert(TileSegment(code: CodeBlock(id: UUID())), thenType: false)
    }

    // A URL alone on a line becomes a bookmark as soon as the word is finished.
    // Inline links stay text — see LinkDetector for why.
    private func detectLink() {
        guard let textView = controller.textView,
              let id = controller.activeID,
              let index = segments.index(of: id),
              segments[index].isText
        else { return }

        // The text view, not the binding: the binding is a frame behind.
        let text = textView.attributedText ?? NSAttributedString()
        guard let found = LinkDetector.standaloneLink(
            in: text.string as NSString,
            near: textView.selectedRange.location
        ) else { return }

        // The run in the editor is ahead of the one in segments, so it is taken
        // across before the line is cut out of it.
        segments[index].text = text

        let bookmark = TileSegment(link: LinkBlock(id: UUID(), url: found.url.absoluteString))
        let following = segments.insert(bookmark, into: id, replacing: found.range)

        segments.normalise()
        if let following { controller.focus(following, at: 0) }
    }

    private func addTable() {
        insert(TileSegment(table: TableBlock(id: UUID())), thenType: false)
    }

    // A widget breaks the run of text at the caret's line: the text above stays
    // in one run, the text below starts another, and the widget sits between.
    // With nothing focused it goes on the end.
    private func insert(_ widget: TileSegment, thenType: Bool) {
        let point = insertionPoint
        insertionPoint = nil

        guard let point,
              let index = segments.index(of: point.segmentID),
              segments[index].isText
        else {
            segments.append(widget)
            segments.normalise()
            if thenType, let last = segments.last { controller.focus(last.id, at: 0) }
            return
        }

        let text = segments[index].text
        let caret = min(point.location, text.length)
        let cut = text.length == 0
            ? 0
            : NSMaxRange((text.string as NSString).paragraphRange(for: NSRange(location: caret, length: 0)))

        let following = segments.insert(
            widget,
            into: point.segmentID,
            replacing: NSRange(location: cut, length: 0)
        )
        if thenType, let following { controller.focus(following, at: 0) }
    }

    private func removeWidget(_ id: UUID) {
        guard let index = segments.index(of: id), !segments[index].isText else { return }

        WidgetStore.delete(segments[index])
        if focusedTable?.id == id { focusedTable = nil }

        withAnimation(.spring(response: 0.34, dampingFraction: 0.8)) {
            segments.remove(at: index)
        }

        if index < segments.count, segments[index].isText {
            join(into: segments[index].id)
        }
        segments.normalise()

        if segments.allSatisfy(\.isText) { stopEditingWidgets() }
    }

    // Backspace at the very start of a run. An empty widget above it is taken
    // the way a character would be; a recording or a written panel is deleted
    // on purpose, from its own badge.
    private func mergeBack(_ id: UUID) -> Bool {
        guard let index = segments.index(of: id), index > 0 else { return false }

        let above = segments[index - 1]
        if !above.isText {
            guard above.isEmptyWidget else { return true }
            WidgetStore.delete(above)
            if focusedTable?.id == above.id { focusedTable = nil }
            segments.remove(at: index - 1)
        }

        join(into: id)
        segments.normalise()
        return true
    }

    private func join(into id: UUID) {
        guard let caret = segments.joinBackwards(into: id) else { return }
        controller.focus(id, at: caret)
    }

    private func focusEnd() {
        stopEditingWidgets()
        guard let last = segments.lastText else { return }
        controller.focus(last.id, at: last.text.length)
    }

    // MARK: Deleting widgets

    private func holdWidgets() {
        // The keyboard would cover half the note and the format bar means
        // nothing while widgets are being removed.
        controller.endEditing()
        withAnimation(.easeOut(duration: 0.2)) { isEditingWidgets = true }
    }

    private func stopEditingWidgets() {
        guard isEditingWidgets else { return }
        withAnimation(.easeOut(duration: 0.2)) { isEditingWidgets = false }
    }

    private func confirmRemove(_ id: UUID) {
        pendingWidget = id
        isConfirmingWidget = true
    }

    private var pendingWidgetName: String {
        guard let id = pendingWidget,
              let segment = segments.first(where: { $0.id == id })
        else { return "widget" }

        if segment.clip != nil { return "voice memo" }
        if segment.drawing != nil { return "drawing" }
        if segment.photo != nil { return "photo" }
        if segment.code != nil { return "code block" }
        if segment.table != nil { return "table" }
        if segment.link != nil { return "bookmark" }
        return "panel"
    }

    // MARK: Loading and saving

    // The archived text has whatever ink colour it was written with baked in.
    private func load() {
        controller.inkColor = UIColor(tileColor.ink)
        controller.fillColor = UIColor(tileColor.fill)
        segments = TileCodec.decode(tile.bodyData)
        segments.repaint(ink: UIColor(tileColor.ink))
        segments.normalise()
    }

    private func reload() {
        controller.inkColor = UIColor(tileColor.ink)
        controller.fillColor = UIColor(tileColor.fill)
        segments.repaint(ink: UIColor(tileColor.ink))
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
        tile.bodyData = TileCodec.encode(segments)
        tile.plainText = TileCodec.plainText(segments)
        tile.touch()
    }

    // Deleted on the next pass, once the pop has finished — writing to or reading a removed
    // model mid-transition is a crash.
    private func remove() {
        let context = context
        let tile = tile
        WidgetStore.deleteAll(in: segments)

        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                context.delete(tile)
            }
        }
    }

    // A tile with no title and no content is not a tile — it goes back to being a free slot.
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
