import AVFoundation
import Foundation

@Observable
final class AudioPlayback: NSObject, AVAudioPlayerDelegate {
    private(set) var isPlaying = false
    private(set) var remaining: TimeInterval = 0
    private(set) var progress: Double = 0

    private var player: AVAudioPlayer?
    private var ticker: Timer?

    func toggle(id: UUID, duration: TimeInterval) {
        if isPlaying {
            pause()
        } else {
            play(id: id, duration: duration)
        }
    }

    private func play(id: UUID, duration: TimeInterval) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)

        if player == nil {
            player = try? AVAudioPlayer(contentsOf: AudioStore.url(for: id))
            player?.delegate = self
        }
        guard let player else { return }

        player.play()
        isPlaying = true

        ticker = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
            self.remaining = max(0, player.duration - player.currentTime)
        }
    }

    func pause() {
        player?.pause()
        ticker?.invalidate()
        ticker = nil
        isPlaying = false
    }

    func reset() {
        pause()
        player?.currentTime = 0
        progress = 0
        remaining = 0
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        reset()
    }
}
