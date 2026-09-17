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

/// App-level preferences. These are settings rather than content, so they live
/// in UserDefaults and never touch the SwiftData schema.
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
        appearance == .dark ? Color(hex: 0x141210) : Theme.canvas
    }

    var canvasInk: Color {
        appearance == .dark ? Color(hex: 0xF5F0E6) : Theme.ink
    }

    var slotFill: Color {
        appearance == .dark ? Color(hex: 0x1D1A16) : Color(hex: 0xF7F1E4)
    }

    var slotOutline: Color {
        appearance == .dark ? Color(hex: 0x4A433A) : Color(hex: 0xC7B99D)
    }

    // MARK: Panels
    //
    // Sheets and settings follow the appearance. Tiles do not — they keep
    // their own palette colours whatever the board is doing.

    var panel: Color {
        appearance == .dark ? Color(hex: 0x1A1714) : Theme.canvas
    }

    var panelSurface: Color {
        appearance == .dark ? Color(hex: 0x262119) : Theme.surface
    }

    var panelInk: Color {
        appearance == .dark ? Color(hex: 0xF5F0E6) : Theme.ink
    }

    func color(_ index: Int) -> TileColor {
        TilePalettes.color(index, in: palette)
    }

    var colors: [TileColor] {
        TilePalettes.colors(for: palette)
    }
}
