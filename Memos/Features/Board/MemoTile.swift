import SwiftUI

/// Maps a Memo onto StickyCard. The mapping lives here so the component
/// itself stays model-free.
struct MemoTile: View {
    let memo: Memo

    var body: some View {
        StickyCard(tilt: memo.tilt) {
            if memo.isBlank {
                blank
            } else {
                filled
            }
        }
    }

    private var blank: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.faint)
                Spacer()
            }
            Spacer()
        }
    }

    private var filled: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(memo.displayTitle)
                .font(Typography.tileTitle)
                .foregroundStyle(Theme.ink)
                .lineLimit(2)

            Text(memo.text)
                .font(Typography.tileBody)
                .foregroundStyle(Theme.muted)
                .lineLimit(4)

            Spacer(minLength: 0)

            Text(memo.updatedAt.formatted(.relative(presentation: .numeric)))
                .font(Typography.tileFooter)
                .foregroundStyle(Theme.faint)
        }
    }
}
