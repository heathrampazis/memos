import Foundation
import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Tile.createdAt) private var tiles: [Tile]

    @State private var openTile: Tile?
    @State private var isEditorOpen = false
    @State private var isArranging = false
    @State private var pendingDelete: Tile?
    @State private var isConfirmingDelete = false
    @State private var isShowingSettings = false

    // A tile whose delete has been confirmed but whose model is still being torn down.
    // It is kept off the board for that window so the editor never pops back onto a board
    // still showing the tile the user just deleted.
    @State private var hiddenTileID: PersistentIdentifier?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                header
                board
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.homeBottomInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            // There is nothing to type into on the board, so a keyboard on its way out from
            // the editor must not be allowed to inset it — that inset is what squashed the
            // tiles for the moment the keyboard took to go.
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .background(settings.canvas)
            .contentShape(Rectangle())
            .onTapGesture { stopArranging() }
            .navigationDestination(isPresented: $isEditorOpen) {
                if let openTile {
                    TileEditorView(tile: openTile) {
                        hide(openTile)
                    }
                }
            }
            .onChange(of: isEditorOpen) { _, presented in
                guard !presented else { return }
                DispatchQueue.main.async { openTile = nil }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .confirmationDialog(
                "Delete this tile?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible,
                presenting: pendingDelete
            ) { tile in
                Button("Delete", role: .destructive) { delete(tile) }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("The tile and everything in it will be removed.")
            }
        }
    }

    private var header: some View {
        HStack {
            Text("memos")
                .font(Typography.wordmark)
                .kerning(-1)
                .foregroundStyle(settings.canvasInk)
            Spacer()

            if isArranging {
                Button("Done") { stopArranging() }
                    .font(Typography.barLabel)
                    .foregroundStyle(settings.canvasInk)
                    .transition(.opacity)
            } else {
                CircleIconButton(systemImage: "gearshape", tint: settings.canvasInk) {
                    isShowingSettings = true
                }
                .transition(.opacity)
            }
        }
        .padding(.bottom, 18)
    }

    // The board is fixed: eight places, always on one screen.
    private var board: some View {
        VStack(spacing: Spacing.gridGap) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(spacing: Spacing.gridGap) {
                    ForEach(rows[index]) { slot in
                        view(for: slot)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func view(for slot: Slot) -> some View {
        switch slot {
        case .tile(let tile, let index):
            BoardTile(
                tile: tile,
                color: settings.color(tile.colorIndex),
                index: index,
                isEditing: isArranging,
                onOpen: { open(tile) },
                onHold: { startArranging() },
                onDelete: { confirmDelete(tile) }
            )
            .transition(
                .asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.2).combined(with: .opacity)
                )
            )

        case .free:
            FreeSlotView(
                fill: settings.slotFill,
                outline: settings.slotOutline,
                action: addTile
            )
                .disabled(isArranging)
                .opacity(isArranging ? 0.45 : 1)
        }
    }

    // MARK: Actions

    private func open(_ tile: Tile) {
        // Opening anything means no delete is in flight, so nothing should still be hidden.
        hiddenTileID = nil
        openTile = tile
        isEditorOpen = true
    }

    // Deliberately not animated: the editor is still covering the board while this runs, so
    // the tile should simply be absent when the board comes back rather than animating out
    // in front of the user.
    private func hide(_ tile: Tile) {
        hiddenTileID = tile.persistentModelID
    }

    private func addTile() {
        guard tiles.count < Tile.boardCapacity else { return }

        let tile = Tile()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.68)) {
            context.insert(tile)
        }
        open(tile)
    }

    private func confirmDelete(_ tile: Tile) {
        pendingDelete = tile
        isConfirmingDelete = true
    }

    private func delete(_ tile: Tile) {
        pendingDelete = nil
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            context.delete(tile)
        }
        if tiles.count <= 1 { stopArranging() }
    }

    private func startArranging() {
        withAnimation(.easeOut(duration: 0.2)) { isArranging = true }
    }

    private func stopArranging() {
        guard isArranging else { return }
        withAnimation(.easeOut(duration: 0.2)) { isArranging = false }
    }

    // MARK: Layout

    private enum Slot: Identifiable {
        case tile(Tile, Int)
        case free(Int)

        var id: AnyHashable {
            switch self {
            case .tile(let tile, _): AnyHashable(tile.persistentModelID)
            case .free(let index): AnyHashable("free-\(index)")
            }
        }
    }

    // Real tiles first, then empty places up to the board's capacity.
    private var slots: [Slot] {
        var slots: [Slot] = []

        for tile in tiles {
            if slots.count == Tile.boardCapacity { break }
            if tile.persistentModelID == hiddenTileID { continue }
            slots.append(.tile(tile, slots.count))
        }

        for index in slots.count..<Tile.boardCapacity {
            slots.append(.free(index))
        }

        return slots
    }

    // The board is two slots wide.
    private var rows: [[Slot]] {
        let slots = self.slots
        var rows: [[Slot]] = []
        var row: [Slot] = []

        for slot in slots {
            row.append(slot)
            if row.count == 2 {
                rows.append(row)
                row = []
            }
        }

        // An odd number of slots leaves one on its own at the end.
        if !row.isEmpty {
            rows.append(row)
        }

        return rows
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Tile.self, inMemory: true)
}
