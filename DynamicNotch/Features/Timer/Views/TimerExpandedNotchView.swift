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
    
    @Environment(\.isNotchlessScreen) var isNotchlessScreen
    @Environment(\.locale) private var locale
    @ObservedObject var viewModel: VM
    @State private var isControlActionRunning = false
    
    private var pauseButtonSymbol: String {
        source.isPaused ? "play.fill" : "pause.fill"
    }
    
    var body: some View {
        VStack {
            HStack {
                leftContent
                Spacer()
                rightContent
            }
        }
        .padding(.top, isNotchlessScreen ? 0 : 28)
        .padding(.leading, isNotchlessScreen ? 15 : 32)
        .padding(.trailing, isNotchlessScreen ? 18 : 38)
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
        HStack(alignment: .firstTextBaseline) {
            Text(locale.dn("notch.timer.title", fallback: "Timer"))
                .font(.system(size: 14))
                .foregroundStyle(Color.orange.opacity(0.8))
            
            if source.isPaused {
                countdownText(seconds: source.displayedSeconds(at: .now))
            } else {
                TimelineView(.periodic(from: countdownScheduleStart, by: 1)) { context in
                    countdownText(seconds: source.displayedSeconds(at: context.date))
                }
            }
        }
    }
    
    private var countdownScheduleStart: Date {
        let now = Date.now
        guard let endDate = source.countdownEndDate else { return now }
        return TimerCountdownSchedule.start(endDate: endDate.addingTimeInterval(-source.countdownFlipOffset), now: now)
    }
    
    private func countdownText(seconds: Int) -> some View {
        let hours = seconds / 3600
        
        return Text(formattedDuration(seconds))
            .font(.system(size: hours > 0 ? 26 : 36, weight: .thin))
            .monospacedDigit()
            .foregroundStyle(Color.orange)
            // SwiftUI reverses countsDown for apps that target macOS 14, so false rolls the digits
            // down here, like Clock. Use true once the app targets macOS 15 or later.
            .contentTransition(.numericText(countsDown: false))
            .animation(.snappy(duration: 0.3), value: seconds)
    }
    
    private func formattedDuration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
