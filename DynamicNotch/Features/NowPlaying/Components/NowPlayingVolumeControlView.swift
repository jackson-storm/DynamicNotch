import SwiftUI

struct NowPlayingVolumeControlView: View {
    @ObservedObject var model: SoundControlModel

    var body: some View {
        HStack(spacing: 10) {
            Button { model.toggleMute() } label: {
                Image(systemName: model.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 13))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .disabled(!model.canToggleMute)
            .accessibilityLabel(Text(model.isMuted ? LocalizedStringKey("homeTools.sound.unmute") : LocalizedStringKey("homeTools.sound.mute")))

            Slider(value: Binding(get: { model.volume }, set: { model.setVolume($0) }), in: 0...1) {
                Text("homeTools.sound.volume")
            }
            .labelsHidden()
            .tint(.white)
            .disabled(!model.canSetVolume)
            .opacity(model.canSetVolume ? 1 : 0.35)

            Text(verbatim: model.canSetVolume ? "\(Int((model.volume * 100).rounded()))%" : "—")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 34, alignment: .trailing)
        }
        .foregroundStyle(.white.opacity(0.8))
        .help(Text(LocalizedStringKey(model.volumeChangeFailed ? "homeTools.sound.volumeFailed" : model.usesMonitorVolume ? "homeTools.sound.monitor" : model.canSetVolume ? "homeTools.sound.system" : "homeTools.sound.hardware")))
    }
}
