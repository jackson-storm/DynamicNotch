import SwiftUI

struct HudDisplayNotchContent: NotchContentProtocol {
    let id = "hud.display"
    let level: Int
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 220, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(HudContent(image: "sun.max.fill", text: "Display", level: 70))
    }
}

struct HudKeyboardNotchContent: NotchContentProtocol {
    let id = "hud.keyboard"
    let level: Int
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 220, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(HudContent(image: "light.max", text: "Keyboard", level: 10))
    }
}

struct HudVolumeNotchContent: NotchContentProtocol {
    let id = "hud.volume"
    let level: Int
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 220, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(HudContent(image: "speaker.wave.3.fill", text: "Volume", level: 50))
    }
}

private struct HudContent: View {
    @Environment(\.notchScale) var scale
    
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
        .padding(.horizontal, 16.scaled(by: scale))
        .font(.system(size: 14))
        .foregroundColor(.white.opacity(0.8))
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
