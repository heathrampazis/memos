import Foundation

// Meter readings taken while recording, reduced to the handful of bars the card actually draws.
enum AudioSamples {
    static let barCount = 34

    // Averages the trace down to one value per bar.
    static func thinned(_ samples: [Float]) -> [Float] {
        guard samples.count > barCount else { return samples }

        let width = Double(samples.count) / Double(barCount)
        var bars: [Float] = []

        for index in 0..<barCount {
            let start = Int(Double(index) * width)

            // Every bar has to cover at least one reading, or a short trace would
            // produce empty slices and divide by zero below.
            var end = Int(Double(index + 1) * width)
            if end < start + 1 {
                end = start + 1
            }
            if end > samples.count {
                end = samples.count
            }

            var total: Float = 0
            for position in start..<end {
                total += samples[position]
            }

            let count = Float(end - start)
            bars.append(total / count)
        }

        return bars
    }

    // The tail of a recording in progress, padded so the bars fill in from the right rather
    // than stretching to fit.
    static func live(_ samples: [Float]) -> [Float] {
        let tail = Array(samples.suffix(barCount))
        guard tail.count < barCount else { return tail }
        return Array(repeating: 0.04, count: barCount - tail.count) + tail
    }
}
