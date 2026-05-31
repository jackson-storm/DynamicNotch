import SwiftUI

struct LocalTimerExpandedNotchView: View {
    @ObservedObject var localTimerViewModel: LocalTimerViewModel
    @Environment(\.isDynamicIsland) var isDynamicIsland
    
    var body: some View {
        VStack {
            if !isDynamicIsland {
                Spacer()
            }
            HStack {
                leftContent
                Spacer()
                rightContent
            }
        }
        .padding(.horizontal, isDynamicIsland ? 20 : 32)
        .padding(.trailing, 3)
        .padding(.bottom, isDynamicIsland ? 0 : 12)
    }
    
    private var leftContent: some View {
        HStack {
            Button {
                if localTimerViewModel.state == .paused {
                    localTimerViewModel.resume()
                } else {
                    localTimerViewModel.pause()
                }
            } label: {
                Image(systemName: localTimerViewModel.state == .paused ? "play.fill" : "pause.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.orange)
            }
            .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .orange.opacity(0.3)))
            
            Button {
                localTimerViewModel.stop()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20))
                    .bold()
                    .foregroundStyle(.white.opacity(0.8))
            }
            .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .gray.opacity(0.3)))
        }
    }
    
    private var rightContent: some View {
        HStack {
            Text(verbatim: "Timer")
                .font(.system(size: 14))
                .foregroundStyle(Color.orange.opacity(0.8))
                .offset(y: 8)
            
            TimelineView(.animation(minimumInterval: 0.25, paused: localTimerViewModel.state == .paused || localTimerViewModel.state == .stopped)) { context in
                Text(formattedDuration(localTimerViewModel.remainingTime(at: context.date)))
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
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
