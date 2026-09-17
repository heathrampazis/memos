import Foundation

/// Meter readings taken while recording, reduced to the handful of bars the
/// card actually draws. Kept apart from the view so the recorder can thin a
/// finished take without knowing anything about SwiftUI.
enum AudioSamples {
    static let barCount = 34

    /// Averages the trace down to one value per bar.
    static func thinned(_ samples: [Float]) -> [Float] {
        guard samples.count > barCount else { return samples }
        let width = Double(samples.count) / Double(barCount)
        return (0..<barCount).map { index in
            let start = Int(Double(index) * width)
            let end = min(samples.count, max(start + 1, Int(Double(index + 1) * width)))
            let slice = samples[start..<end]
            return slice.reduce(0, +) / Float(slice.count)
        }
    }

    /// The tail of a recording in progress, padded so the bars fill in from the
    /// right rather than stretching to fit.
    static func live(_ samples: [Float]) -> [Float] {
        let tail = Array(samples.suffix(barCount))
        guard tail.count < barCount else { return tail }
        return Array(repeating: 0.04, count: barCount - tail.count) + tail
    }
}
