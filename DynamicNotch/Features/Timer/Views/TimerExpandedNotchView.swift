import SwiftUI

struct TimerExpandedNotchView: View {
    let source: TimerSource
    
    init(source: TimerSource) {
        self.source = source
    }
    
    init(timerViewModel: TimerViewModel) {
        self.source = .system(timerViewModel)
    }
    
    var body: some View {
        Group {
            switch source {
            case .system(let vm):
                TimerExpandedNotchViewInternal(source: source, viewModel: vm)
                
            case .local(let vm):
                TimerExpandedNotchViewInternal(source: source, viewModel: vm)
            }
        }
    }
}

private struct TimerExpandedNotchViewInternal<VM: ObservableObject>: View {
    let source: TimerSource
    
    @Environment(\.isDynamicIsland) var isDynamicIsland
    @ObservedObject var viewModel: VM
    @State private var isControlActionRunning = false
    
    private var pauseButtonSymbol: String {
        source.isPaused ? "play.fill" : "pause.fill"
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                leftContent
                Spacer()
                rightContent
            }
        }
        .padding(.leading, isDynamicIsland ? 14 : 32)
        .padding(.trailing, isDynamicIsland ? 18 : 38)
        .padding(.bottom, isDynamicIsland ? 14 : 12)
    }
    
    private var leftContent: some View {
        HStack {
            Button {
                guard !isControlActionRunning else { return }
                
                Task { @MainActor in
                    isControlActionRunning = true
                    defer { isControlActionRunning = false }
                    await source.togglePauseResume()
                }
            } label: {
                Image(systemName: pauseButtonSymbol)
                    .font(.system(size: 20))
                    .foregroundStyle(.orange)
            }
            .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .orange.opacity(0.3)))
            .disabled(isControlActionRunning)
            
            Button {
                guard !isControlActionRunning else { return }
                
                Task { @MainActor in
                    isControlActionRunning = true
                    defer { isControlActionRunning = false }
                    await source.stopTimer()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .gray.opacity(0.3)))
            .disabled(isControlActionRunning)
        }
    }
    
    private var rightContent: some View {
        HStack {
            Text(verbatim: "Timer")
                .font(.system(size: 14))
                .foregroundStyle(Color.orange.opacity(0.8))
                .offset(y: 8)
            
            TimelineView(.animation(minimumInterval: 0.25, paused: source.isPaused)) { context in
                let remaining = source.remainingTime(at: context.date)
                let roundedSeconds = max(0, Int(remaining.rounded()))
                let hours = roundedSeconds / 3600
                
                Text(formattedDuration(remaining))
                    .font(.system(size: hours > 0 ? 26 : 36, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.orange)
                    .contentTransition(.numericText())
            }
        }
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let roundedSeconds = max(0, Int(duration.rounded()))
        let hours = roundedSeconds / 3600
        let minutes = (roundedSeconds % 3600) / 60
        let seconds = roundedSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
