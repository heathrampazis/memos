import Foundation
import SwiftUI

// A voice memo, sitting between two runs of text in the note's scroll.
struct AudioWidget: View {
    @Binding var clip: AudioClip
    let color: TileColor

    @State private var recorder = AudioRecorder()
    @State private var playback = AudioPlayback()

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 13) {
                actionButton

                Waveform(
                    samples: waveformSamples,
                    progress: playback.progress,
                    played: color.ink.opacity(0.85),
                    pending: color.ink.opacity(playback.isPlaying ? 0.28 : 0.72)
                )
                .animation(.easeOut(duration: 0.08), value: recorder.elapsed)

                Text(AudioStore.formatted(time))
                    .font(Typography.barLabel)
                    .monospacedDigit()
                    .foregroundStyle(color.inkSecondary)
            }

            caption
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color.ink.opacity(0.10))
        )
        .onDisappear {
            playback.pause()
            // Not saved: the widget may be going away because it was just
            // deleted, and writing a finished clip back through a binding whose
            // segment has gone is how you get a crash instead of a recording.
            if recorder.isRecording { recorder.cancel(id: clip.id) }
        }
    }

    // MARK: Pieces

    private var actionButton: some View {
        Button(action: primaryAction) {
            Group {
                if recorder.isRecording {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(color.fill)
                        .frame(width: 13, height: 13)
                } else {
                    Image(systemName: glyph)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(color.fill)
                }
            }
            .frame(width: 44, height: 44)
            .background(Circle().fill(color.ink))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(actionLabel)
    }

    private var caption: some View {
        Group {
            if recorder.permissionDenied {
                Text("Microphone access is off — turn it on for Memos in Settings.")
                    .foregroundStyle(color.inkSecondary)
            } else if clip.isEmpty && !recorder.isRecording {
                Text("Tap to record")
                    .foregroundStyle(color.inkTertiary)
            } else if recorder.isRecording {
                Text("Recording…")
                    .foregroundStyle(color.inkSecondary)
            } else {
                // Named in place rather than through a sheet: one tap on the
                // caption is the whole interaction.
                TextField("", text: $clip.name)
                    .textFieldStyle(.plain)
                    .foregroundStyle(color.inkSecondary)
                    .submitLabel(.done)
                    .overlay(alignment: .leading) {
                        if clip.name.isEmpty {
                            Text("Voice memo")
                                .foregroundStyle(color.inkTertiary)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
        .font(Typography.barLabel)
        .padding(.leading, 3)
    }

    // MARK: State

    private var glyph: String {
        if clip.isEmpty { return "mic.fill" }
        if playback.isPlaying {
            return "pause.fill"
        }
        return "play.fill"
    }

    private var actionLabel: String {
        if recorder.isRecording { return "Stop recording" }
        if clip.isEmpty { return "Record" }
        if playback.isPlaying {
            return "Pause"
        }
        return "Play"
    }

    private var time: TimeInterval {
        if recorder.isRecording { return recorder.elapsed }
        if playback.isPlaying { return playback.remaining }
        return clip.duration
    }

    private var waveformSamples: [Float] {
        recorder.isRecording ? AudioSamples.live(recorder.samples) : clip.samples
    }

    // MARK: Actions

    private func primaryAction() {
        if recorder.isRecording {
            finishRecording()
        } else if clip.isEmpty {
            playback.reset()
            recorder.start(id: clip.id)
        } else {
            playback.toggle(id: clip.id, duration: clip.duration)
        }
    }

    private func finishRecording() {
        guard let finished = recorder.stop(id: clip.id, name: clip.name) else { return }
        clip = finished
    }

}

extension Binding where Value == AudioClip? {
    // ForEach hands back a binding to the whole segment; the card only wants the clip, and it
    // is only ever built when one is there.
    func required() -> Binding<AudioClip> {
        Binding<AudioClip>(
            get: { self.wrappedValue ?? AudioClip(id: UUID()) },
            set: { self.wrappedValue = $0 }
        )
    }
}
