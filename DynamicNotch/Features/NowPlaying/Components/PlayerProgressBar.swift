//
//  PlayerProgressBar.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct PlayerProgressBar: View {
    @Environment(\.onScrubbingChanged) private var onScrubbingChanged

    let progress: CGFloat
    let displayedElapsedTime: TimeInterval
    let duration: TimeInterval
    let isInteractive: Bool
    let tintGradient: LinearGradient?
    let primaryColor: Color
    let secondaryColor: Color
    let onScrubChanged: (CGFloat) -> Void
    let onScrubEnded: (CGFloat) -> Void
    
    @State private var scaleEffect: Bool = false
    @State private var isHovering: Bool = false
    
    var body: some View {
        HStack(spacing: 10) {
            Text(formattedTime(displayedElapsedTime))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(scaleEffect ? .white.opacity(0.8) : primaryColor)
            
            GeometryReader { proxy in
                let resolvedProgress = min(max(progress, 0), 1)
                let trackHeight: CGFloat = scaleEffect ? 11 : 7
                let filledWidth = proxy.size.width * resolvedProgress
                
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(.white.opacity(0.15))
                        .frame(height: trackHeight)
                    
                    if let tintGradient {
                        Rectangle()
                            .fill(tintGradient)
                            .frame(width: filledWidth, height: trackHeight)
                    } else {
                        Rectangle()
                            .fill(scaleEffect ? .white.opacity(0.8) : .white.opacity(0.5))
                            .frame(width: filledWidth, height: trackHeight)
                    }
                }
                .clipShape(Capsule(style: .continuous))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .onHover { isHovered in
                    guard isInteractive else { return }
                    isHovering = isHovered
                    if !scaleEffect {
                        onScrubbingChanged(isHovered)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard isInteractive else { return }
                            scaleEffect = true
                            onScrubbingChanged(true)
                            onScrubChanged(progress(at: value.location.x, in: proxy.size.width))
                        }
                        .onEnded { value in
                            guard isInteractive else { return }
                            scaleEffect = false
                            onScrubEnded(progress(at: value.location.x, in: proxy.size.width))
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                onScrubbingChanged(isHovering)
                            }
                        }
                )
            }
            .frame(height: 18)
            
            Text(duration > 0 ? formattedTime(duration) : "LIVE")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(scaleEffect ? .white : secondaryColor)
        }
        .onDisappear {
            onScrubbingChanged(false)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scaleEffect)
    }
    
    private func progress(at locationX: CGFloat, in width: CGFloat) -> CGFloat {
        guard width > 0 else { return 0 }
        return min(max(locationX / width, 0), 1)
    }
    
    private func formattedTime(_ time: TimeInterval) -> String {
        guard time.isFinite else { return "--:--" }
        
        let totalSeconds = max(0, Int(time.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
