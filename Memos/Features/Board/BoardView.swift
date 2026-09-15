import SwiftData
import SwiftUI

struct BoardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Memo.createdAt) private var memos: [Memo]

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.gridGap),
        GridItem(.flexible(), spacing: Spacing.gridGap),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: Spacing.gridGap) {
                    ForEach(memos) { memo in
                        NavigationLink {
                            MemoEditorView(memo: memo)
                        } label: {
                            MemoTile(memo: memo)
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
        guard memos.isEmpty else { return }
        for _ in 0..<8 {
            context.insert(Memo())
        }
    }
}

#Preview {
    BoardView()
        .modelContainer(for: Memo.self, inMemory: true)
}
