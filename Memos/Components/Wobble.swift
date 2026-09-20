import SwiftUI

// The home-screen jiggle.
struct Wobble: ViewModifier {
    let active: Bool
    let seed: Int

    @State private var swung = false

    // Small enough to read as restlessness rather than shaking. The seed spreads
    // the periods so a board of tiles never swings in unison.
    private static let swing = 0.7
    private static let beat = 0.155

    private var period: Double {
        Self.beat + Double(seed % 4) * 0.014
    }

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(active ? (swung ? Self.swing : -Self.swing) : 0))
            .animation(
                active
                    ? .easeInOut(duration: period).repeatForever(autoreverses: true)
                    : .easeOut(duration: 0.18),
                value: swung
            )
            .onChange(of: active) { _, isActive in
                swung = isActive
            }
    }
}

extension View {
    func wobble(_ active: Bool, seed: Int) -> some View {
        modifier(Wobble(active: active, seed: seed))
    }
}
