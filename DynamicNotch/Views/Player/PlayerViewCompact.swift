import SwiftUI

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
