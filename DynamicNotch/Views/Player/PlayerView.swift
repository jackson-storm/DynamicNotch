import SwiftUI
import Combine

struct PlayerView: View {
    @StateObject private var playerViewModel = PlayerViewModel()
    @EnvironmentObject var layout: NotchLayoutViewModel
  
    var body: some View {
        ZStack {
            switch layout.state {
            case .compact:
                if playerViewModel.isPlaying {
                    PlayerViewCompact()
                        .transition(.blurAndFade
                            .animation(.snappy(duration: 0.8))
                            .combined(with: .scale(scale: 0.6, anchor: .center))
                        )
                }
            case .expanded:
                PlayerViewExpanded()
                    .transition(.blurAndFade
                        .animation(.snappy(duration: 0.6))
                        .combined(with: .scale(scale: 0.4, anchor: .top))
                    )
            }
        }
    }
}

#Preview {
   NotchContentView()
}
