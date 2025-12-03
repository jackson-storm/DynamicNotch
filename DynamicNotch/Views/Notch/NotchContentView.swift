import SwiftUI

struct NotchContentView: View {
    @StateObject private var layout = NotchLayoutViewModel()
    @StateObject private var playerViewModel = PlayerViewModel()
   
    var body: some View {
        ZStack(alignment: .top) {
            NotchContainer(kind: .player) {
                PlayerView()
                    
            }
        }
        .frame(width: 500, height: 300, alignment: .top)
        .environmentObject(layout)
        .environmentObject(playerViewModel)
    }
}

#Preview {
    NotchContentView()
        .frame(width: 500, height: 300)
}
