import SwiftUI
import Combine

struct DynamicNotchView: View {
    @EnvironmentObject var notch: NotchManager
    weak var window: NSWindow?

    var notchSize: CGSize {
        switch notch.current {
        case .none: return CGSize(width: 226, height: 38)
        case .music: return CGSize(width: 290, height: 38)
        case .notification: return CGSize(width: 350, height: 200)
        case .charger: return CGSize(width: 405, height: 38)
        }
    }

    var notchCornerRadius: (top: CGFloat, bottom: CGFloat) {
        switch notch.current {
        case .none: return (top: 9, bottom: 13)
        case .music: return (top: 9, bottom: 13)
        case .notification: return (top: 18, bottom: 26)
        case .charger: return (top: 9, bottom: 13)
        }
    }

    var body: some View {
        VStack {
            ZStack {
                NotchShape(topCornerRadius: notchCornerRadius.top, bottomCornerRadius: notchCornerRadius.bottom)
                    .fill(Color.black)
                    .overlay(
                        NotchShape(topCornerRadius: notchCornerRadius.top, bottomCornerRadius: notchCornerRadius.bottom)
                            .fill(.clear)
                            .stroke(notch.current == .none ? Color.clear : .white.opacity(0.1), lineWidth: 2)
                            .padding(.top, -0.8)
                    )
                
                ZStack {
                    Group {
                        switch notch.current {
                        case .none: EmptyView()
                        case .music: Text("Music")
                        case .notification: Text("Notification")
                        case .charger: ChargerNotch(powerSourceMonitor: PowerSourceMonitor())
                        }
                    }
                    .id(notch.current)
                    .transition(.blurAndFade.animation(.spring(duration: 0.5)).combined(with: .scale))
                }
            }
            .frame(width: notchSize.width, height: notchSize.height)
            .onHover { hovering in
                window?.ignoresMouseEvents = !hovering
            }
            
            HStack(spacing: 15) {
                Button("Charger") { withAnimation { notch.show(.charger) } }
                Button("Music") { withAnimation { notch.show(.music) } }
                Button("Notification") { withAnimation { notch.show(.notification) } }
                Button("Hide") { withAnimation { notch.hide() } }
            }
            .padding()
            .onHover { hovering in
                window?.ignoresMouseEvents = !hovering
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
