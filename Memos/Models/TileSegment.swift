import Foundation
import UIKit

// A note is an ordered run of text and widgets, not one string.
struct TileSegment: Identifiable, Equatable {
    let id: UUID
    var text: NSAttributedString
    var clip: AudioClip?
    var panel: PanelBlock?
    var drawing: DrawingBlock?
    var photo: PhotoBlock?
    var code: CodeBlock?
    var table: TableBlock?
    var link: LinkBlock?

    init(id: UUID = UUID(), text: NSAttributedString = NSAttributedString()) {
        self.id = id
        self.text = text
    }

    init(id: UUID = UUID(), clip: AudioClip) {
        self.id = id
        self.text = NSAttributedString()
        self.clip = clip
    }

    init(id: UUID = UUID(), panel: PanelBlock) {
        self.id = id
        self.text = NSAttributedString()
        self.panel = panel
    }

    init(id: UUID = UUID(), drawing: DrawingBlock) {
        self.id = id
        self.text = NSAttributedString()
        self.drawing = drawing
    }

    init(id: UUID = UUID(), photo: PhotoBlock) {
        self.id = id
        self.text = NSAttributedString()
        self.photo = photo
    }

    init(id: UUID = UUID(), code: CodeBlock) {
        self.id = id
        self.text = NSAttributedString()
        self.code = code
    }

    init(id: UUID = UUID(), table: TableBlock) {
        self.id = id
        self.text = NSAttributedString()
        self.table = table
    }

    init(id: UUID = UUID(), link: LinkBlock) {
        self.id = id
        self.text = NSAttributedString()
        self.link = link
    }

    var isText: Bool {
        clip == nil && panel == nil && drawing == nil
            && photo == nil && code == nil && table == nil && link == nil
    }

    // A widget nothing has been put into yet.
    var isEmptyWidget: Bool {
        if let clip = clip { return clip.isEmpty }
        if let panel = panel { return panel.text.isEmpty }
        if let drawing = drawing { return drawing.isEmpty }
        if let photo = photo { return photo.isEmpty }
        if let code = code { return code.isEmpty }
        if let table = table { return table.isEmpty }
        if let link = link { return link.isEmpty }
        return false
    }
}
