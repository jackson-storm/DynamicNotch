import SwiftUI

struct PlayerNotchLarge: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var playerViewModel: PlayerViewModel
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                title
                progressBar.padding(.top, 15.scaled(by: scale))
                Spacer()
                playerButton
            }
            .padding(.top, 25.scaled(by: scale))
            .padding(.horizontal, 45.scaled(by: scale))
        }
    }
    
    @ViewBuilder
    var title: some View {
        HStack(spacing: 15.scaled(by: scale)) {
            Group {
                if let art = playerViewModel.artwork {
                    art
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "music.note")
                            .font(.largeTitle)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .frame(width: 55.scaled(by: scale), height: 55.scaled(by: scale))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playerViewModel.title)
                    .font(.system(size: 13.scaled(by: scale), weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(playerViewModel.artist)
                    .font(.system(size: 14.scaled(by: scale), weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            Spacer()
            
            Image(systemName: "waveform")
                .font(.system(size: 24.scaled(by: scale)))
                .foregroundStyle(.white.opacity(0.8))
                .symbolEffect(.variableColor.iterative, isActive: playerViewModel.isPlaying)
        }
    }
    
    @ViewBuilder
    var progressBar: some View {
        HStack(spacing: 8) {
            Text(playerViewModel.formatTime(playerViewModel.currentTime))
                .font(.system(size: 10.scaled(by: scale), weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 6.scaled(by: scale))
                    
                    let progress = playerViewModel.duration > 0 ? (playerViewModel.currentTime / playerViewModel.duration) : 0
                    
                    Capsule()
                        .fill(.white)
                        .frame(width: geo.size.width * CGFloat(progress), height: 6.scaled(by: scale))
                }
            }
            .frame(height: 6.scaled(by: scale))
            
            Text("-" + playerViewModel.formatTime(playerViewModel.duration - playerViewModel.currentTime))
                .font(.system(size: 10.scaled(by: scale), weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    @ViewBuilder
    var playerButton: some View {
        HStack(spacing: 40.scaled(by: scale)) {
            Spacer()
            Button(action: { playerViewModel.prevTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 20.scaled(by: scale)))
            }
            Button(action: { playerViewModel.playPause() }) {
                Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32.scaled(by: scale)))
            }
            Button(action: { playerViewModel.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 20.scaled(by: scale)))
            }
            Spacer()
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundStyle(.white)
    }
}

struct PlayerNotchSmall: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    
    @Environment(\.notchScale) var scale
    
    var body: some View {
        HStack {
            image
            Spacer()
            equalizer
        }
        .padding(.horizontal, 2.scaled(by: scale))
        .padding(.bottom, 2.scaled(by: scale))
    }
    
    @ViewBuilder
    private var image: some View {
        Image("primer")
            .resizable()
            .cornerRadius(6.scaled(by: scale))
            .frame(width: 26.scaled(by: scale), height: 26.scaled(by: scale))
    }
    
    @ViewBuilder
    private var equalizer: some View {
        Image(systemName: "waveform.mid")
            .resizable()
            .frame(width: 20.scaled(by: scale), height: 20.scaled(by: scale))
            .padding(.trailing, 3.scaled(by: scale))
    }
}

#Preview {
    ZStack(alignment: .top) {
        PlayerNotchLarge(playerViewModel: PlayerViewModel())
            .frame(width: 400, height: 190)
            .background(
                NotchShape(topCornerRadius: 32, bottomCornerRadius: 46)
                    .fill(.black)
            )
        
        NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
            .stroke(.red, lineWidth: 1)
            .frame(width: 226, height: 38)
    }
    .frame(width: 420, height: 220, alignment: .top)
}
