import SwiftUI

/// Picks the tile's background. The sheet wears the tray tone of the colour it
/// is setting, and the editor behind updates as you tap, so the choice is
/// previewed rather than committed blind.
struct TileColorPicker: View {
    @Environment(AppSettings.self) private var settings
    @Binding var selection: Int
    var onDelete: () -> Void

    @State private var isConfirmingDelete = false

    private var current: TileColor {
        settings.color(selection)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            swatches
            Spacer(minLength: 0)
            deleteButton
        }
        .padding(.horizontal, Spacing.screen)
        .padding(.top, 24)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(current.tray)
        .animation(.easeOut(duration: 0.2), value: selection)
        .presentationDetents([.height(268)])
        .presentationDragIndicator(.visible)
        .presentationBackground(current.tray)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            isConfirmingDelete = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .semibold))
                Text("Delete tile")
                    .font(Typography.barLabel)
            }
            .foregroundStyle(current.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(current.ink.opacity(0.09))
            )
        }
        .buttonStyle(.plain)
        .confirmationDialog("Delete this tile?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The tile and everything in it will be removed.")
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("Tile colour")
                .font(Typography.sheetTitle)
                .foregroundStyle(Theme.ink)

            Spacer(minLength: 0)

            // Same ink pill the format bar uses for an active control, so the
            // two sheets read as one family.
            Text(current.name)
                .font(Typography.barLabel)
                .foregroundStyle(current.fill)
                .padding(.horizontal, 13)
                .frame(height: 32)
                .background(Capsule().fill(Theme.ink))
        }
    }

    private var swatches: some View {
        HStack(spacing: 0) {
            ForEach(settings.colors) { color in
                swatch(color)
            }
        }
    }

    /// Each swatch is a tile in miniature — same fill, same hard shadow.
    private func swatch(_ color: TileColor) -> some View {
        let chosen = color.id == selection
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

        return Button {
            selection = color.id
        } label: {
            shape
                .fill(color.fill)
                .frame(width: 40, height: 40)
                .overlay(shape.strokeBorder(color.edge, lineWidth: 1))
                .background(shape.fill(color.shadow).offset(y: 2.5))
                .overlay {
                    shape
                        .strokeBorder(current.ink, lineWidth: 2.5)
                        .opacity(chosen ? 1 : 0)
                }
                .scaleEffect(chosen ? 1.1 : 1)
                .frame(maxWidth: .infinity, minHeight: 54)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(color.name)
        .accessibilityAddTraits(chosen ? [.isSelected] : [])
    }
}
