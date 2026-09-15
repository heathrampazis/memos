import Foundation
import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Tile.createdAt) private var tiles: [Tile]

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
        }
        .task { seedIfNeeded() }
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

    /// The board is fixed: eight tiles, always on one screen. Rows share the
    /// height that is left rather than each tile having a set size, so the
    /// grid fits every device without scrolling.
    private var board: some View {
        VStack(spacing: Spacing.gridGap) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(spacing: Spacing.gridGap) {
                    ForEach(rows[index]) { tile in
                        NavigationLink {
                            TileEditorView(tile: tile)
                        } label: {
                            TileView(tile: tile)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .buttonStyle(.plain)
                    }

                    // Keeps a half-filled row's tile the same width as the rest.
                    if rows[index].count == 1 {
                        Color.clear
                    }
                }
            }
        }
    }

    private var rows: [[Tile]] {
        stride(from: 0, to: tiles.count, by: 2).map { start in
            Array(tiles[start..<min(start + 2, tiles.count)])
        }
    }

    /// The board holds exactly this many tiles and no more.
    private func seedIfNeeded() {
        guard tiles.isEmpty else { return }
        for _ in 0..<Tile.boardCapacity {
            context.insert(Tile())
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Tile.self, inMemory: true)
}
