import SwiftUI

/// The home-screen jiggle. Each tile is given a slightly different period so
/// the board does not move in lockstep, which reads as mechanical.
struct Wobble: ViewModifier {
    let active: Bool
    let seed: Int

    @State private var swung = false

    private var period: Double {
        0.125 + Double(seed % 4) * 0.012
    }

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(active ? (swung ? 1.1 : -1.1) : 0))
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
