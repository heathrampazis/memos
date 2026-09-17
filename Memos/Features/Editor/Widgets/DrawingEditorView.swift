import Foundation
import PencilKit
import SwiftUI

/// A screen of its own. A sketch wants the whole display and a tool bar that
/// stays put, neither of which fits inside a card in the middle of a note.
struct DrawingEditorView: View {
    let color: TileColor
    var onSave: (PKDrawing) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var controller: DrawingController

    init(id: UUID, color: TileColor, onSave: @escaping (PKDrawing) -> Void) {
        self.color = color
        self.onSave = onSave
        _controller = State(initialValue: DrawingController(drawing: DrawingStore.load(id) ?? PKDrawing()))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            DrawingCanvas(controller: controller)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            toolbar
        }
        .background(color.fill)
    }

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(Typography.barLabel)
                .foregroundStyle(color.inkSecondary)

            Spacer(minLength: 0)

            Text("Drawing")
                .font(Typography.barLabel)
                .foregroundStyle(color.ink)

            Spacer(minLength: 0)

            Button("Done") {
                onSave(controller.drawing)
                dismiss()
            }
            .font(Typography.barLabel)
            .foregroundStyle(color.fill)
            .padding(.horizontal, 16)
            .frame(height: 34)
            .background(Capsule().fill(color.ink))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.screen)
        .padding(.vertical, 12)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            ForEach(DrawingInk.allCases) { ink in
                swatch(ink)
            }

            eraser

            Spacer(minLength: 0)

            iconButton("arrow.uturn.backward", enabled: controller.canUndo) { controller.undo() }
            iconButton("arrow.uturn.forward", enabled: controller.canRedo) { controller.redo() }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 22)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: Spacing.trayRadius,
                topTrailingRadius: Spacing.trayRadius,
                style: .continuous
            )
            .fill(color.tray)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(color.ink.opacity(0.10))
                    .frame(height: 1)
            }
        }
    }

    private func swatch(_ ink: DrawingInk) -> some View {
        let chosen = controller.tool == .ink(ink)

        return Button {
            controller.tool = .ink(ink)
        } label: {
            Circle()
                .fill(ink.color)
                .frame(width: 26, height: 26)
                // The ring sits outside the dot, so picking a colour does not
                // change how much of that colour you can see.
                .overlay {
                    Circle()
                        .strokeBorder(color.ink, lineWidth: 2.5)
                        .padding(-5)
                        .opacity(chosen ? 1 : 0)
                }
                .frame(width: 38, height: 38)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(ink.rawValue.capitalized)
        .accessibilityAddTraits(chosen ? [.isSelected] : [])
    }

    private var eraser: some View {
        Button {
            controller.tool = .eraser
        } label: {
            Image(systemName: "eraser.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(controller.isEraser ? color.fill : color.ink)
                .frame(width: 38, height: 38)
                .background(Circle().fill(controller.isEraser ? color.ink : color.ink.opacity(0.10)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Eraser")
        .accessibilityAddTraits(controller.isEraser ? [.isSelected] : [])
    }

    private func iconButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color.ink.opacity(enabled ? 0.85 : 0.25))
                .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
