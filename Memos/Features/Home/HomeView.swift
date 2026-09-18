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

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                header
                board
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.homeBottomInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(settings.canvas)
            .contentShape(Rectangle())
            .onTapGesture { stopArranging() }
            .navigationDestination(isPresented: $isEditorOpen) {
                if let openTile {
                    TileEditorView(tile: openTile)
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
        openTile = tile
        isEditorOpen = true
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
        var slots = tiles.prefix(Tile.boardCapacity).enumerated().map { Slot.tile($1, $0) }
        for index in slots.count..<Tile.boardCapacity {
            slots.append(.free(index))
        }
        return slots
    }

    private var rows: [[Slot]] {
        stride(from: 0, to: slots.count, by: 2).map { start in
            Array(slots[start..<min(start + 2, slots.count)])
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Tile.self, inMemory: true)
}
