import SwiftUI

struct SoundControlNotchView: View {
    @ObservedObject var model: SoundControlModel
    let isActive: Bool
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Spacer(minLength: 0)
            HStack {
                Text("homeTools.sound.title").font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(verbatim: model.canSetVolume ? "\(Int((model.volume * 100).rounded()))%" : "—")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.55))
            }
            HStack(spacing: 12) {
                Button { model.toggleMute() } label: {
                    Image(systemName: model.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 16))
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.12), in: Circle())
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
            }
            Menu {
                ForEach(model.routes) { route in
                    Button { model.select(route) } label: {
                        if route.isCurrent { Label(route.name, systemImage: "checkmark") }
                        else { Text(route.name) }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: model.currentRoute?.systemImageName ?? "speaker.wave.2.fill")
                    if let route = model.currentRoute { Text(route.name).lineLimit(1) }
                    else { Text("homeTools.sound.output") }
                    Spacer(minLength: 0)
                }
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            .menuStyle(.borderlessButton)
            .disabled(model.routes.isEmpty)
            .accessibilityLabel(Text("homeTools.sound.output"))
            Text(statusText)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(2)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, isNotchlessScreen ? 22 : 40)
        .padding(.bottom, 16)
        .onAppear { if isActive { model.startObserving() } }
        .onChange(of: isActive) { _, active in
            if active { model.startObserving() } else { model.stopObserving() }
        }
        .onDisappear { model.stopObserving() }
    }

    private var statusText: LocalizedStringKey {
        if model.routeChangeFailed { return "homeTools.sound.routeFailed" }
        if model.volumeChangeFailed { return "homeTools.sound.volumeFailed" }
        if model.usesMonitorVolume { return "homeTools.sound.monitor" }
        return model.canSetVolume ? "homeTools.sound.system" : "homeTools.sound.hardware"
    }
}
