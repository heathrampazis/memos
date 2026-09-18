import Foundation
import PencilKit
import SwiftUI
import UIKit

enum DrawingTool: Equatable {
    case ink(DrawingInk)
    case eraser
}

// A canvas that owns its undo stack.
final class DrawingCanvasView: PKCanvasView {
    let history = UndoManager()

    override var undoManager: UndoManager? { history }
}

@Observable
final class DrawingController {
    var tool: DrawingTool = .ink(.black)

    private(set) var canUndo = false
    private(set) var canRedo = false

    @ObservationIgnored weak var canvas: DrawingCanvasView?
    @ObservationIgnored private let initial: PKDrawing

    init(drawing: PKDrawing) {
        initial = drawing
    }

    // The canvas is the only copy.
    var drawing: PKDrawing {
        canvas?.drawing ?? initial
    }

    var pkTool: PKTool {
        switch tool {
        case .ink(let ink):
            return PKInkingTool(.pen, color: UIColor(ink.color), width: 5)
        case .eraser:
            return PKEraserTool(.bitmap)
        }
    }

    var isEraser: Bool {
        tool == .eraser
    }

    func undo() {
        guard let history = canvas?.history, history.canUndo else { return }
        history.undo()
        refresh()
    }

    func redo() {
        guard let history = canvas?.history, history.canRedo else { return }
        history.redo()
        refresh()
    }

    func refresh() {
        canUndo = canvas?.history.canUndo ?? false
        canRedo = canvas?.history.canRedo ?? false
    }
}

struct DrawingCanvas: UIViewRepresentable {
    let controller: DrawingController

    func makeUIView(context: Context) -> DrawingCanvasView {
        let canvas = DrawingCanvasView()
        canvas.delegate = context.coordinator
        // Finger drawing, not pencil only — this is a phone note, not an iPad.
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.alwaysBounceVertical = false
        canvas.alwaysBounceHorizontal = false
        // The canvas is a fixed page, not a scrollable one — without this a
        // pinch zooms the drawing and the strokes stop landing under the finger.
        canvas.isScrollEnabled = false
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 1
        canvas.drawing = controller.drawing
        canvas.tool = controller.pkTool

        // Loading the existing sketch is not an edit, so undo must not walk back
        // past it to an empty page.
        canvas.history.removeAllActions()

        controller.canvas = canvas
        controller.refresh()
        return canvas
    }

    func updateUIView(_ canvas: DrawingCanvasView, context: Context) {
        canvas.tool = controller.pkTool
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(controller)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        private let controller: DrawingController

        init(_ controller: DrawingController) {
            self.controller = controller
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            controller.refresh()
        }
    }
}
