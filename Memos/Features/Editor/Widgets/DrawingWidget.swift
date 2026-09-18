import Foundation
import SwiftUI
import UIKit
import PencilKit

// The sketch as it sits in the note: a preview you tap to edit, and a handle under it to set
// how much of the note it takes up.
struct DrawingWidget: View {
    @Binding var block: DrawingBlock
    let color: TileColor

    @State private var preview: UIImage?
    @State private var isEditing = false
    @State private var heightAtStart: Double?

    // The height while a drag is in flight.
    @State private var dragHeight: Double?

    var body: some View {
        VStack(spacing: 0) {
            canvas
                .frame(height: dragHeight ?? block.height)
            handle
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color.ink.opacity(0.10))
        )
        .fullScreenCover(isPresented: $isEditing) {
            DrawingEditorView(id: block.id, color: color) { drawing in
                DrawingStore.save(drawing, id: block.id)
                block.isEmpty = drawing.strokes.isEmpty
                block.revision += 1
                loadPreview()
            }
        }
        .onAppear(perform: loadPreview)
        .onChange(of: block.revision) { loadPreview() }
    }

    private var canvas: some View {
        Button {
            isEditing = true
        } label: {
            Group {
                if let preview {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                } else {
                    VStack(spacing: 7) {
                        Image(systemName: "scribble.variable")
                            .font(.system(size: 24, weight: .semibold))
                        Text("Tap to draw")
                            .font(Typography.barLabel)
                    }
                    .foregroundStyle(color.inkTertiary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // Dragged rather than dialled: the right size is whatever looks right next to the text
    // above it, which is not a number anyone would type.
    private var handle: some View {
        Capsule()
            .fill(color.ink.opacity(0.22))
            .frame(width: 38, height: 4)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            // High priority, or the note's scroll takes the drag first.
            .highPriorityGesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        let base = heightAtStart ?? block.height
                        heightAtStart = base
                        dragHeight = min(
                            max(base + value.translation.height, DrawingBlock.minimumHeight),
                            DrawingBlock.maximumHeight
                        )
                    }
                    .onEnded { _ in
                        if let dragHeight { block.height = dragHeight }
                        heightAtStart = nil
                        dragHeight = nil
                    }
            )
            .accessibilityLabel("Resize drawing")
    }

    private func loadPreview() {
        preview = DrawingStore.image(for: block.id)
    }
}

extension Binding where Value == DrawingBlock? {
    func required() -> Binding<DrawingBlock> {
        Binding<DrawingBlock>(
            get: { self.wrappedValue ?? DrawingBlock(id: UUID()) },
            set: { self.wrappedValue = $0 }
        )
    }
}
