import Foundation
import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Tile.createdAt) private var tiles: [Tile]

    @State private var newTile: Tile?
    @State private var isEditingNewTile = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                header
                board
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.homeBottomInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.canvas)
            .navigationDestination(isPresented: $isEditingNewTile) {
                if let newTile {
                    TileEditorView(tile: newTile)
                }
            }
            .onChange(of: isEditingNewTile) { _, presented in
                // Let go of the reference once the editor is gone, so a tile
                // discarded for being blank is not held on to here.
                guard !presented else { return }
                DispatchQueue.main.async { newTile = nil }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("memos")
                .font(Typography.wordmark)
                .kerning(-1)
                .foregroundStyle(Theme.ink)
            Spacer()
        }
        .padding(.bottom, 18)
    }

    /// The board is fixed: eight places, always on one screen. Rows share the
    /// height that is left rather than each tile having a set size, so the
    /// grid fits every device without scrolling.
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
        case .tile(let tile):
            NavigationLink {
                TileEditorView(tile: tile)
            } label: {
                TileView(tile: tile)
            }
            .buttonStyle(.plain)
            .transition(.scale(scale: 0.8).combined(with: .opacity))

        case .free:
            FreeSlotView(action: addTile)
        }
    }

    /// The slot becomes a tile and opens straight away, so tapping + puts you
    /// in the note rather than on the board looking at it.
    private func addTile() {
        guard tiles.count < Tile.boardCapacity else { return }

        let tile = Tile()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.68)) {
            context.insert(tile)
        }

        newTile = tile
        isEditingNewTile = true
    }

    // MARK: Layout

    private enum Slot: Identifiable {
        case tile(Tile)
        case free(Int)

        var id: AnyHashable {
            switch self {
            case .tile(let tile): AnyHashable(tile.persistentModelID)
            case .free(let index): AnyHashable("free-\(index)")
            }
        }
    }

    /// Real tiles first, then empty places up to the board's capacity.
    private var slots: [Slot] {
        var slots = tiles.prefix(Tile.boardCapacity).map(Slot.tile)
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
