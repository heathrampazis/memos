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
            ForEach(0..<bars.count, id: \.self) { index in
                Capsule()
                    .fill(fraction(index) < progress ? played : pending)
                    .frame(width: 2.5, height: 4 + CGFloat(bars[index]) * 26)
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
        if samples.isEmpty {
            return Array(repeating: 0.08, count: AudioSamples.barCount)
        }
        return samples
    }
}
