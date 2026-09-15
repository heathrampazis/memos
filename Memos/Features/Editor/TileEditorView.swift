import SwiftUI

struct TileEditorView: View {
    @Bindable var tile: Tile
    @FocusState private var focus: Field?

    private enum Field { case title, text }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Title", text: $tile.title, axis: .vertical)
                    .font(Typography.editorTitle)
                    .foregroundStyle(Theme.ink)
                    .focused($focus, equals: .title)
                    .submitLabel(.next)
                    .onSubmit { focus = .text }

                TextField("Start writing…", text: $tile.text, axis: .vertical)
                    .font(Typography.editorBody)
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(5)
                    .focused($focus, equals: .text)
            }
            .textFieldStyle(.plain)
            .padding(Spacing.screen)
        }
        .background(Theme.card)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: tile.title) { tile.touch() }
        .onChange(of: tile.text) { tile.touch() }
    }
}
