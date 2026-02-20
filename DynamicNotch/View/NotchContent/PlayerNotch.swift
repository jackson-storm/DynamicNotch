import SwiftUI

struct PlayerNotchLarge: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                title
                progressBar.padding(.top)
                Spacer()
                playerButton
            }
            .padding(.top, 40)
            .padding(.horizontal, 55)
            .padding(.bottom, 20)
        }
    }
    
    @ViewBuilder
    var title: some View {
        HStack(spacing: 15) {
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
            .frame(width: 55, height: 55)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playerViewModel.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(playerViewModel.artist)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            Spacer()
            
            Image(systemName: "waveform")
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.8))
                .symbolEffect(.variableColor.iterative, isActive: playerViewModel.isPlaying)
        }
    }
    
    @ViewBuilder
    var progressBar: some View {
        HStack(spacing: 8) {
            Text(playerViewModel.formatTime(playerViewModel.currentTime))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 6)
                    
                    let progress = playerViewModel.duration > 0 ? (playerViewModel.currentTime / playerViewModel.duration) : 0
                    
                    Capsule()
                        .fill(.white)
                        .frame(width: geo.size.width * CGFloat(progress), height: 6)
                }
            }
            .frame(height: 6)
            
            Text("-" + playerViewModel.formatTime(playerViewModel.duration - playerViewModel.currentTime))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    @ViewBuilder
    var playerButton: some View {
        HStack(spacing: 40) {
            Spacer()
            Button(action: { playerViewModel.prevTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 20))
            }
            Button(action: { playerViewModel.playPause() }) {
                Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32))
            }
            Button(action: { playerViewModel.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 20))
            }
            Spacer()
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundStyle(.white)
    }
}

struct PlayerNotchSmall: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    
    var body: some View {
        HStack {
            image
            Spacer()
            equalizer
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 2)
    }
    
    @ViewBuilder
    private var image: some View {
        Image("primer")
            .resizable()
            .cornerRadius(6)
            .frame(width: 26, height: 26)
    }
    
    @ViewBuilder
    private var equalizer: some View {
        Image(systemName: "waveform.mid")
            .resizable()
            .frame(width: 20, height: 20)
            .padding(.trailing, 3)
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
