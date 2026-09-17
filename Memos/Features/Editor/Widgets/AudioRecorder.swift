import AVFoundation
import Foundation

@Observable
final class AudioRecorder {
    private(set) var isRecording = false
    private(set) var elapsed: TimeInterval = 0
    private(set) var level: Float = 0
    private(set) var permissionDenied = false

    /// The live meter trace. Kept at full rate while recording so the bars move
    /// with the voice, then thinned down to one value per bar on stop.
    private(set) var samples: [Float] = []

    private var recorder: AVAudioRecorder?
    private var ticker: Timer?

    func start(id: UUID) {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                guard granted else {
                    self.permissionDenied = true
                    return
                }
                self.beginRecording(id: id)
            }
        }
    }

    private func beginRecording(id: UUID) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? session.setActive(true)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        guard let recorder = try? AVAudioRecorder(url: AudioStore.url(for: id), settings: settings) else {
            return
        }
        recorder.isMeteringEnabled = true
        recorder.record()

        self.recorder = recorder
        isRecording = true
        elapsed = 0
        samples = []

        ticker = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let recorder = self.recorder else { return }
            recorder.updateMeters()
            self.elapsed = recorder.currentTime
            // Decibels are negative and logarithmic; this maps them onto 0...1.
            let decibels = recorder.averagePower(forChannel: 0)
            let level = max(0, min(1, (decibels + 50) / 50))
            self.level = level
            self.samples.append(level)
        }
    }

    /// Returns the finished clip, or nil when nothing usable was captured.
    func stop(id: UUID, name: String) -> AudioClip? {
        ticker?.invalidate()
        ticker = nil
        let duration = recorder?.currentTime ?? elapsed
        recorder?.stop()
        recorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])

        guard duration > 0.4, AudioStore.exists(id) else {
            AudioStore.delete(id)
            return nil
        }
        return AudioClip(
            id: id,
            name: name,
            duration: duration,
            samples: AudioSamples.thinned(samples)
        )
    }

    func cancel(id: UUID) {
        ticker?.invalidate()
        ticker = nil
        recorder?.stop()
        recorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        AudioStore.delete(id)
    }
}
