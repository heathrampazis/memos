import Foundation
import PencilKit
import SwiftUI
import UIKit

enum DrawingTool: Equatable {
    case ink(DrawingInk)
    case eraser
}

/// Holds the canvas and its history.
///
/// PencilKit has an undo manager of its own, but it belongs to the responder
/// chain and a sheet's chain is not reliably ours. Keeping snapshots is a few
/// lines, survives the eraser, and makes redo honest.
@Observable
final class DrawingController {
    var tool: DrawingTool = .ink(.black)

    private(set) var canUndo = false
    private(set) var canRedo = false
    private(set) var drawing: PKDrawing

    @ObservationIgnored weak var canvas: PKCanvasView?

    private var history: [PKDrawing]
    private var index = 0
    private var isRestoring = false

    private static let historyLimit = 40

    init(drawing: PKDrawing) {
        self.drawing = drawing
        self.history = [drawing]
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

    func record(_ drawing: PKDrawing) {
        guard !isRestoring else { return }
        self.drawing = drawing

        // Anything ahead of here was undone. Drawing again is a new branch, so
        // the old one goes.
        if index + 1 < history.count {
            history.removeSubrange((index + 1)...)
        }
        history.append(drawing)
        if history.count > Self.historyLimit {
            history.removeFirst()
        }
        index = history.count - 1
        updateFlags()
    }

    func undo() {
        guard index > 0 else { return }
        index -= 1
        restore()
    }

    func redo() {
        guard index + 1 < history.count else { return }
        index += 1
        restore()
    }

    private func restore() {
        isRestoring = true
        drawing = history[index]
        canvas?.drawing = drawing
        isRestoring = false
        updateFlags()
    }

    private func updateFlags() {
        canUndo = index > 0
        canRedo = index + 1 < history.count
    }
}

struct DrawingCanvas: UIViewRepresentable {
    let controller: DrawingController

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
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

        controller.canvas = canvas
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
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
            controller.record(canvasView.drawing)
        }
    }
}
