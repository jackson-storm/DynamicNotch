import SwiftUI

struct HudDisplayView: View {
    var body: some View {
        HudContent(image: "sun.max.fill", text: "Display", level: 70)
    }
}

struct HudKeyboardView: View {
    var body: some View {
        HudContent(image: "light.max", text: "Keyboard", level: 10)
    }
}

struct HudVolumeView: View {
    var body: some View {
        HudContent(image: "speaker.wave.3.fill", text: "Volume", level: 50)
    }
}

private struct HudContent: View {
    var image: String
    var text: String
    var level: Int
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: image)
                Text(text)
            }
            
            Spacer()
            
            HStack {
                Text("\(level)")
                indicator
            }
        }
        .font(.system(size: 14))
        .foregroundColor(.white.opacity(0.8))
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var indicator: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 60, height: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 60, height: 6)
            )
    }
}

#Preview {
    VStack {
        ZStack {
            HudContent(image: "speaker.wave.3.fill", text: "Volume", level: 50)
                .frame(width: 440, height: 38)
                .background(
                    NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                        .fill(.black)
                )
            
            if #available(macOS 14.0, *) {
                NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                    .fill(.black)
                    .stroke(.red.opacity(0.3), lineWidth: 1)
                    .frame(width: 226, height: 38)
            } else {
                NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                    .stroke(.red.opacity(0.3), lineWidth: 1)
                    .frame(width: 226, height: 38)
            }
        }
        
        ZStack {
            HudContent(image: "sun.max.fill", text: "Display", level: 70)
                .frame(width: 440, height: 38)
                .background(
                    NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                        .fill(.black)
                )
            
            if #available(macOS 14.0, *) {
                NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                    .fill(.black)
                    .stroke(.red.opacity(0.3), lineWidth: 1)
                    .frame(width: 226, height: 38)
            } else {
                NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                    .stroke(.red.opacity(0.3), lineWidth: 1)
                    .frame(width: 226, height: 38)
            }
        }
        
        ZStack {
            HudContent(image: "light.max", text: "Keyboard", level: 10)
                .frame(width: 440, height: 38)
                .background(
                    NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                        .fill(.black)
                )
            
            if #available(macOS 14.0, *) {
                NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                    .fill(.black)
                    .stroke(.red.opacity(0.3), lineWidth: 1)
                    .frame(width: 226, height: 38)
            } else {
                NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                    .stroke(.red.opacity(0.3), lineWidth: 1)
                    .frame(width: 226, height: 38)
            }
        }
    }
    .frame(width: 450, height: 200)
}
