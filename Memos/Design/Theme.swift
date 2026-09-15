import SwiftUI

/// Colour tokens. Every colour in the app comes from here.
///
/// Static for now because there is one palette. When palettes become a user
/// setting this becomes an @Observable instance in the environment, and the
/// call sites do not change.
enum Theme {
    static let canvas = Color(light: 0xF1EDE4, dark: 0x14120F)
    static let card = Color(light: 0xFFFFFF, dark: 0x201D18)
    static let cardEdge = Color(light: 0xEDE8DC, dark: 0x2B2620)
    static let cardShadow = Color(light: 0xE2DBCB, dark: 0x0C0B09)

    static let ink = Color(light: 0x17120E, dark: 0xF5F0E6)
    static let muted = Color(light: 0x7C736A, dark: 0x8C8378)
    static let faint = Color(light: 0xA79E93, dark: 0x5E574E)
}
