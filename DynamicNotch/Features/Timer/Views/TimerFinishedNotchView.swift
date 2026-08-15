import SwiftUI

struct TimerFinishedNotchView: View {
    let onDismiss: @MainActor () -> Void
    let onRestart: (@MainActor () -> Void)?

    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    init(
        onDismiss: @escaping @MainActor () -> Void,
        onRestart: (@MainActor () -> Void)? = nil
    ) {
        self.onDismiss = onDismiss
        self.onRestart = onRestart
    }

    var body: some View {
        VStack {
            Spacer()
            content
        }
        .padding(.leading, isDynamicIsland ? 18 : 38)
        .padding(.trailing, isDynamicIsland ? 14 : 32)
        .padding(.bottom, isDynamicIsland ? 14 : 12)
        .onDisappear {
            TimerSoundPlayer.shared.stop()
        }
    }
    
    private var content: some View {
        HStack {
            Text(verbatim: "Timer")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.orange)
            
            Spacer()
            
            if let onRestart {
                Button {
                    TimerSoundPlayer.shared.stop()
                    onRestart()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.orange)
                }
                .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .orange.opacity(0.3)))
            }
            
            Button {
                TimerSoundPlayer.shared.stop()
                onDismiss()
                
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .gray.opacity(0.3)))
        }
    }
}
