//
//  PlayerProgressBar.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct PlayerProgressBar: View {
    let progress: CGFloat
    let isInteractive: Bool
    let tintGradient: LinearGradient?
    let onScrubChanged: (CGFloat) -> Void
    let onScrubEnded: (CGFloat) -> Void
    
    var body: some View {
        GeometryReader { proxy in
            let resolvedProgress = min(max(progress, 0), 1)
            let trackHeight: CGFloat = 7
            let filledWidth = proxy.size.width * resolvedProgress

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.15))
                    .frame(height: trackHeight)

                if let tintGradient {
                    Capsule(style: .continuous)
                        .fill(tintGradient)
                        .frame(width: filledWidth, height: trackHeight)
                } else {
                    Capsule(style: .continuous)
                        .fill(.white.opacity(0.5))
                        .frame(width: filledWidth, height: trackHeight)
                }

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isInteractive else { return }
                        onScrubChanged(progress(at: value.location.x, in: proxy.size.width))
                    }
                    .onEnded { value in
                        guard isInteractive else { return }
                        onScrubEnded(progress(at: value.location.x, in: proxy.size.width))
                    }
            )
        }
        .frame(height: 18)
    }

    private func progress(at locationX: CGFloat, in width: CGFloat) -> CGFloat {
        guard width > 0 else { return 0 }
        return min(max(locationX / width, 0), 1)
    }
}
