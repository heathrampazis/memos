import Foundation
import SwiftUI

/// A voice memo, sitting between two runs of text in the note's scroll. It is a
/// real view rather than a character in the text, so it can hold its own
/// controls and its own state without the editor knowing anything about audio.
struct AudioWidget: View {
    @Binding var clip: AudioClip
    let color: TileColor
    var onDelete: () -> Void

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
        .contextMenu {
            Button(action: rerecord) {
                Label("Record again", systemImage: "arrow.counterclockwise")
            }
            .disabled(recorder.isRecording)

            Button(role: .destructive, action: remove) {
                Label("Delete", systemImage: "trash")
            }
        }
        .onDisappear {
            playback.pause()
            if recorder.isRecording { finishRecording() }
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
                TextField("Voice memo", text: $clip.name)
                    .textFieldStyle(.plain)
                    .foregroundStyle(color.inkSecondary)
                    .submitLabel(.done)
            }
        }
        .font(Typography.barLabel)
        .padding(.leading, 3)
    }

    // MARK: State

    private var glyph: String {
        if clip.isEmpty { return "mic.fill" }
        return playback.isPlaying ? "pause.fill" : "play.fill"
    }

    private var actionLabel: String {
        if recorder.isRecording { return "Stop recording" }
        if clip.isEmpty { return "Record" }
        return playback.isPlaying ? "Pause" : "Play"
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

    private func rerecord() {
        playback.reset()
        AudioStore.delete(clip.id)
        clip.duration = 0
        clip.samples = []
        recorder.start(id: clip.id)
    }

    private func remove() {
        playback.pause()
        if recorder.isRecording { recorder.cancel(id: clip.id) }
        onDelete()
    }
}

extension Binding where Value == AudioClip? {
    /// ForEach hands back a binding to the whole segment; the card only wants
    /// the clip, and it is only ever built when one is there.
    func required() -> Binding<AudioClip> {
        Binding<AudioClip>(
            get: { self.wrappedValue ?? AudioClip(id: UUID()) },
            set: { self.wrappedValue = $0 }
        )
    }
}
