import Foundation
import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Tile.createdAt) private var tiles: [Tile]

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.gridGap),
        GridItem(.flexible(), spacing: Spacing.gridGap),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: Spacing.gridGap) {
                    ForEach(tiles) { tile in
                        NavigationLink {
                            TileEditorView(tile: tile)
                        } label: {
                            TileView(tile: tile)
                                .frame(height: Spacing.tileHeight)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, 32)
            }
            .background(Theme.canvas)
            .safeAreaInset(edge: .top) { header }
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
        .padding(.horizontal, Spacing.screen)
        .padding(.bottom, 18)
        .background(Theme.canvas)
    }

    /// Eight blank tiles on first launch. Replaced by real creation in M2-4.
    private func seedIfNeeded() {
        guard tiles.isEmpty else { return }
        for _ in 0..<8 {
            context.insert(Tile())
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Tile.self, inMemory: true)
}
