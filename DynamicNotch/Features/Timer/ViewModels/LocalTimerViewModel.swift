import SwiftUI
import Combine

enum LocalTimerState {
    case stopped
    case running
    case paused
}

class LocalTimerViewModel: ObservableObject {
    @Published var state: LocalTimerState = .stopped
    @Published var remainingTime: TimeInterval = 0
    
    var totalTime: TimeInterval = 0
    var endDate: Date?
    var pausedRemaining: TimeInterval?
    
    private var timer: AnyCancellable?
    
    func start(hours: Int, minutes: Int, seconds: Int) {
        totalTime = TimeInterval(hours * 3600 + minutes * 60 + seconds)
        guard totalTime > 0 else { return }
        remainingTime = totalTime
        pausedRemaining = nil
        endDate = Date().addingTimeInterval(totalTime)
        resume()
    }
    
    func pause() {
        state = .paused
        timer?.cancel()
        if let endDate = endDate {
            pausedRemaining = max(0, endDate.timeIntervalSince(Date()))
        }
        remainingTime = pausedRemaining ?? 0
    }
    
    func resume() {
        state = .running
        if let pausedRemaining = pausedRemaining {
            endDate = Date().addingTimeInterval(pausedRemaining)
        } else {
            endDate = Date().addingTimeInterval(remainingTime)
        }
        pausedRemaining = nil
        
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                let rem = self.remainingTime(at: Date())
                self.remainingTime = rem
                if rem <= 0 {
                    self.stop()
                }
            }
    }
    
    func stop() {
        state = .stopped
        timer?.cancel()
        remainingTime = 0
        endDate = nil
        pausedRemaining = nil
    }
    
    func remainingTime(at date: Date) -> TimeInterval {
        switch state {
        case .stopped:
            return 0
        case .paused:
            return pausedRemaining ?? 0
        case .running:
            guard let endDate = endDate else { return 0 }
            return max(0, endDate.timeIntervalSince(date))
        }
    }
    
    var formattedRemainingTime: String {
        return formatTime(remainingTime)
    }

    func formatTime(_ remainingTime: TimeInterval) -> String {
        let displaySeconds = max(0, Int(ceil(remainingTime)))

        if displaySeconds < 3600 {
            let minutes = displaySeconds / 60
            let seconds = displaySeconds % 60
            return String(format: "%d:%02d", minutes, seconds)
        }

        let hours = displaySeconds / 3600
        let minutes = (displaySeconds % 3600) / 60
        if minutes > 0 {
            return "\(hours)h \(minutes)min"
        }
        return "\(hours)h"
    }
}
