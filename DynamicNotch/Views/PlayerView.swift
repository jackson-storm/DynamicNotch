import SwiftUI
import Combine

struct PlayerView: View {
    @StateObject private var playerViewModel = PlayerViewModel()
    @EnvironmentObject var layout: NotchLayoutViewModel
    @State private var showCompact: Bool = false
  
    var body: some View {
        ZStack {
            switch layout.state {
            case .compact:
                if showCompact && playerViewModel.isPlaying {
                    PlayerViewCompact()
                        .transition(.blurAndFade
                            .animation(.snappy(duration: 0.5))
                            .combined(with: .scale(scale: 0.6, anchor: .center))
                        )
                }
            case .expanded:
                PlayerViewExpanded()
            }
        }
        .onAppear {
            if layout.state == .compact {
                showCompact = playerViewModel.isPlaying
            } else {
                showCompact = false
            }
        }
        .onChange(of: layout.state) { _, newValue in
            switch newValue {
            case .compact:
                showCompact = false
                let isPlayingNow = playerViewModel.isPlaying
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    if layout.state == .compact && isPlayingNow {
                        withAnimation(.snappy) {
                            showCompact = true
                        }
                    }
                }
            case .expanded:
                withAnimation(.snappy) {
                    showCompact = false
                }
            }
        }
    }
}

struct PlayerViewExpanded: View {
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let duration: Double = 215
    
    var body: some View {
        VStack(spacing: 0) {
            title
            progressBar
            musicControlButton
        }
        .padding(.top, 20)
        .padding(45)
        .transition(.blurAndFade
            .animation(.snappy(duration: 0.5))
            .combined(with: .scale(scale: 0.4, anchor: .top))
        )
        .onReceive(timer) { _ in
            guard playerViewModel.isPlaying else { return }
            playerViewModel.currentTime = min(duration, playerViewModel.currentTime + 1)
            playerViewModel.progress = max(0, min(1, playerViewModel.currentTime / duration))
        }
    }
    
    @ViewBuilder
    private var title: some View {
        HStack(spacing: 15) {
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    MarqueeText(text: "PONOS (feat. KAZIMIR)", font: 16, foregroundColor: .white, weight: .medium)
                    MarqueeText(text: "Evgeniy", font: 16, foregroundColor: .gray.opacity(0.8), weight: .regular)
                }
                .padding(.leading, 85)
                
                HStack {
                    Image("primer")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.trailing, 12)
                        .background(.black)
                    
                    Spacer()
                    
                    Image(systemName: "waveform.mid")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .padding(.bottom, 20)
                        .padding(.leading, 12)
                        .background(.black)
                }
            }
        }
    }
    
    @ViewBuilder
    private var progressBar: some View {
        HStack(spacing: 2) {
            Text(playerViewModel.formatTime(playerViewModel.currentTime))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.gray.opacity(0.8))
            
            Spacer()
            
            GeometryReader { geo in
                let width = geo.size.width
                let barHeight: CGFloat = 7
                
                ZStack(alignment: .leading) {
                         Capsule()
                             .fill(.white.opacity(0.12))
                             .frame(height: barHeight)
                         Capsule()
                             .fill(.gray.opacity(0.8))
                             .frame(width: max(0, min(width, width * playerViewModel.progress)), height: barHeight)
                     }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let x = max(0, min(width, value.location.x))
                            let newProgress = Double(x / width)
                            playerViewModel.progress = newProgress
                            playerViewModel.currentTime = newProgress * duration
                        }
                )
                .animation(.linear(duration: 0.15), value: playerViewModel.progress)
            }
            .padding(.top, 3)
            
            Spacer()
            
            Text("-" + playerViewModel.formatTime(max(0, duration - playerViewModel.currentTime)))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.gray.opacity(0.8))
        }
        .padding(.top, 18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Playback progress")
        .accessibilityValue(Text("\(Int(playerViewModel.progress * 100)) percent"))
    }
    
    @ViewBuilder
    private var musicControlButton: some View {
        HStack {
            Button(action: {
                playerViewModel.isFavorites.toggle()
            }) {
                Image(systemName: playerViewModel.isFavorites ? "star.fill" :"star")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.gray.opacity(0.8))
            }
            .buttonStyle(CustomButtonStyle(width: 40, height: 40))
            
            Spacer()
            
            HStack(spacing: 10) {
                Button(action: {}) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }
                Button(action: {
                    playerViewModel.isPlaying.toggle()
                }) {
                    Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(.white)
                }
                Button(action: {}) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(CustomButtonStyle(width: 50, height: 50))
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "hifispeaker.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.gray.opacity(0.8))
            }
            .buttonStyle(CustomButtonStyle(width: 40, height: 40))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct PlayerViewCompact: View {
    var body: some View {
        HStack {
            Image("primer")
                .resizable()
                .frame(width: 25, height: 25)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        
            Spacer()
            
            Image(systemName: "waveform.mid")
                .font(.system(size: 20))
                .foregroundStyle(.white)
        }
        .padding()
    }
}

private struct MarqueeText: View {
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

#Preview {
   NotchContentView()
}

struct NotchSizingModifier: ViewModifier {
    @EnvironmentObject var layout: NotchLayoutViewModel
    let kind: NotchContentKind
    
    func body(content: Content) -> some View {
        let size = layout.size(for: kind)
        return NotchShape(topCornerRadius: size.topCornerRadius, bottomCornerRadius: size.bottomCornerRadius)
            .fill(Color.black)
            .stroke(.black, lineWidth: 1)
            .frame(width: size.width, height: size.height)
            .overlay(content)
    }
}

extension View {
    func notchSizing(kind: NotchContentKind) -> some View {
        modifier(NotchSizingModifier(kind: kind))
    }
}
