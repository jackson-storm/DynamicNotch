import SwiftUI

struct TimerMinimalNotchView: View {
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
                TimerMinimalNotchViewInternal(source: source, viewModel: vm)
                
            case .local(let vm):
                TimerMinimalNotchViewInternal(source: source, viewModel: vm)
            }
        }
    }
}

private struct TimerMinimalNotchViewInternal<VM: ObservableObject>: View {
    let source: TimerSource
    
    @Environment(\.notchScale) private var scale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @ObservedObject var viewModel: VM

    var body: some View {
        HStack {
            TimerCompactIndicatorView(source: source)
            
            Spacer()
            
            TimerCountdownText(source: source)
        }
        .padding(.vertical, 10)
        .padding(.leading, isNotchlessScreen ? 4.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.trailing, isNotchlessScreen ? 6.scaled(by: scale) : 14.scaled(by: scale))
    }
}
