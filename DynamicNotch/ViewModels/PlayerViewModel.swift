import Combine
import SwiftUI

final class PlayerViewModel: ObservableObject {
    @Published var textSize: CGSize = .zero
    @Published var containerWidth: CGFloat = 0
    @Published var xOffset: CGFloat = 0
    @Published var started: Bool = false
    @Published var animationTask: Task<Void, Never>? = nil
    
    @Published var isPlaying: Bool = false
    @Published var isFavorites: Bool = true
    @Published var currentTime: Double = 42
    @Published var progress: Double = 42.0 / 215.0
    
    let speed: Double = 30
    let gap: CGFloat = 10
    let pause: Double = 3

    func startAnimationIfNeeded() {
        guard textSize.width > 0, containerWidth > 0 else { return }
        if animationTask != nil { return }
        let totalTravel = textSize.width + gap
        animationTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(pause * 1_000_000_000))
                xOffset = 0
                let duration = totalTravel / max(1, speed)
                withAnimation(.linear(duration: duration)) {
                    xOffset = -totalTravel
                }
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                try? await Task.sleep(nanoseconds: UInt64(pause * 1_000_000_000))
                
                withAnimation(.none) {
                    xOffset = 0
                }
            }
        }
    }
    
    func formatTime(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
    
    func reset() {
        started = false
        xOffset = 0
        animationTask?.cancel()
        animationTask = nil
    }
}
