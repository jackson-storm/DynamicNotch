import SwiftUI

struct MarqueeText: View {
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    let text: String
    let font: Double
    let foregroundColor: Color
    let weight: Font.Weight
    
    var body: some View {
        GeometryReader { geo in
            let container = geo.size.width
            let needsMarquee = playerViewModel.textSize.width > container && container > 0

            ZStack(alignment: .leading) {
                if needsMarquee {
                    HStack(spacing: 0) {
                        marqueeUnit
                        Color.clear.frame(width: playerViewModel.gap)
                        marqueeUnit
                    }
                    .offset(x: playerViewModel.xOffset)
                    .onAppear {
                        playerViewModel.containerWidth = container
                        playerViewModel.startAnimationIfNeeded()
                    }
                    .onChange(of: container) { _, newValue in
                        playerViewModel.containerWidth = newValue
                        playerViewModel.reset()
                        playerViewModel.startAnimationIfNeeded()
                    }
                    .onChange(of: playerViewModel.textSize) { _, _ in
                        playerViewModel.startAnimationIfNeeded()
                    }
                } else {
                    marqueeUnit
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onAppear {
                            playerViewModel.animationTask?.cancel()
                            playerViewModel.animationTask = nil
                            playerViewModel.reset()
                            playerViewModel.containerWidth = container
                        }
                        .onChange(of: container) { _, newValue in
                            playerViewModel.containerWidth = newValue
                        }
                }
            }
            .clipped()
            .onDisappear {
                playerViewModel.animationTask?.cancel()
                playerViewModel.animationTask = nil
            }
        }
        .frame(height: playerViewModel.textSize.height)
    }
    
    @ViewBuilder
    private var marqueeUnit: some View {
        Text(text)
            .font(.system(size: font, weight: weight))
            .foregroundStyle(foregroundColor)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { playerViewModel.textSize = proxy.size }
                        .onChange(of: proxy.size) { _, newSize in
                            playerViewModel.textSize = newSize
                        }
                }
            )
    }
}
