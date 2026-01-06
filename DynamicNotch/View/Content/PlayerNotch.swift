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
    ZStack {
        PlayerNotch()
            .frame(width: 305, height: 38)
            .background(
                NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                    .fill(.black)
            )
        NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
            .fill(.black)
            .stroke(.red.opacity(0.3), lineWidth: 1)
            .frame(width: 226, height: 38)
    }
    .frame(width: 350, height: 100)
}
