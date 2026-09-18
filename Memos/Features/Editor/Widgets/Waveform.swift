import Foundation
import SwiftUI

// The meter trace, drawn as bars.
struct Waveform: View {
    let samples: [Float]
    var progress: Double = 0
    let played: Color
    let pending: Color

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(Array(bars.enumerated()), id: \.offset) { index, value in
                Capsule()
                    .fill(fraction(index) < progress ? played : pending)
                    .frame(width: 2.5, height: 4 + CGFloat(value) * 26)
            }
        }
        .frame(height: 30)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fraction(_ index: Int) -> Double {
        Double(index) / Double(max(bars.count, 1))
    }

    // An empty clip still draws a bar row, so the card keeps its shape before anything has been
    // recorded.
    private var bars: [Float] {
        samples.isEmpty ? Array(repeating: 0.08, count: AudioSamples.barCount) : samples
    }
}
