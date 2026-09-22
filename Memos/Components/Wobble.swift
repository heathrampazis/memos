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

    // Which way the tile is leaning at this moment. A tile that is not wobbling sits straight.
    private var angle: Double {
        if !active { return 0 }
        if swung { return Self.swing }
        return -Self.swing
    }

    private var motion: Animation {
        if active {
            return .easeInOut(duration: period).repeatForever(autoreverses: true)
        }
        // Coming to rest, rather than stopping mid-swing.
        return .easeOut(duration: 0.18)
    }

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .animation(motion, value: swung)
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
