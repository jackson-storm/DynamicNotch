import SwiftUI

struct PlayerNotch: View {
    var body: some View {
        HStack {
            image
            Spacer()
            equalizer
        }
        .padding(.horizontal, 16)
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
    PlayerNotch()
        .frame(width: 300, height: 38)
}
