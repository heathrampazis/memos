import SwiftUI

enum Appearance: String, CaseIterable, Identifiable, Codable {
    case light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light: .light
        case .dark: .dark
        }
    }
}

// App-level preferences.
@Observable
final class AppSettings {
    var palette: TilePaletteKind {
        didSet { defaults.set(palette.rawValue, forKey: Key.palette) }
    }

    var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }

    private let defaults: UserDefaults

    private enum Key {
        static let palette = "settings.tilePalette"
        static let appearance = "settings.appearance"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        palette = TilePaletteKind(rawValue: defaults.string(forKey: Key.palette) ?? "") ?? .colour
        appearance = Appearance(rawValue: defaults.string(forKey: Key.appearance) ?? "") ?? .light
    }

    // MARK: The board
    //
    // Appearance changes the ground the tiles sit on, and nothing else. Tiles
    // keep their own colours, and panels over them stay light.

    var canvas: Color {
        appearance == .dark ? Color(hex: 0x0E0E10) : Theme.canvas
    }

    var canvasInk: Color {
        appearance == .dark ? Color(hex: 0xF2F2F5) : Theme.ink
    }

    // A shade lighter than the board, so an empty place reads as waiting rather
    // than as a hole.
    var slotFill: Color {
        appearance == .dark ? Color(hex: 0x18181C) : Color(hex: 0xFAFAFC)
    }

    var slotOutline: Color {
        appearance == .dark ? Color(hex: 0x46464F) : Color(hex: 0xC4C4CD)
    }

    // MARK: Panels
    //
    // Sheets and settings follow the appearance. Tiles do not — they keep
    // their own palette colours whatever the board is doing.

    var panel: Color {
        appearance == .dark ? Color(hex: 0x131316) : Theme.canvas
    }

    var panelSurface: Color {
        appearance == .dark ? Color(hex: 0x202026) : Theme.surface
    }

    var panelInk: Color {
        appearance == .dark ? Color(hex: 0xF2F2F5) : Theme.ink
    }

    func color(_ index: Int) -> TileColor {
        TilePalettes.color(index, in: palette)
    }

    var colors: [TileColor] {
        TilePalettes.colors(for: palette)
    }
}
