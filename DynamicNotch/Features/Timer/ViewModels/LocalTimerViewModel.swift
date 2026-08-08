import SwiftUI
import Combine

enum LocalTimerState {
    case stopped
    case running
    case paused
}

@MainActor
final class LocalTimerViewModel: ObservableObject {
    @Published var state: LocalTimerState = .stopped
    @Published var remainingTime: TimeInterval = 0
    
    var totalTime: TimeInterval = 0
    var endDate: Date?
    var pausedRemaining: TimeInterval?
    
    private var timerTask: Task<Void, Never>?
    
    func start(hours: Int, minutes: Int, seconds: Int) {
        totalTime = TimeInterval(hours * 3600 + minutes * 60 + seconds)
        guard totalTime > 0 else { return }
        remainingTime = totalTime
        pausedRemaining = nil
        endDate = Date().addingTimeInterval(totalTime)
        resume()
    }
    
    func pause() {
        guard state == .running else { return }
        state = .paused
        timerTask?.cancel()
        timerTask = nil
        if let endDate = endDate {
            pausedRemaining = max(0, endDate.timeIntervalSince(Date()))
        }
        remainingTime = pausedRemaining ?? 0
    }
    
    func resume() {
        guard remainingTime > 0 || pausedRemaining != nil else { return }
        timerTask?.cancel()
        state = .running
        if let pausedRemaining = pausedRemaining {
            endDate = Date().addingTimeInterval(pausedRemaining)
        } else {
            endDate = Date().addingTimeInterval(remainingTime)
        }
        pausedRemaining = nil
        
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let remaining = self.remainingTime(at: Date())
                self.remainingTime = remaining
                if remaining <= 0 {
                    self.stop()
                    return
                }

                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }
    
    func stop() {
        state = .stopped
        timerTask?.cancel()
        timerTask = nil
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
