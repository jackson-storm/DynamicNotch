import SwiftUI

enum NotchState {
    case compact
    case expanded
    case intermediate
}

struct NotchContainer: View {
    @EnvironmentObject var manager: NotchManager
    @State private var state: NotchState = .compact
    
    var body: some View {
        if let module = manager.topModule {
            
            let size = sizeFor(module: module)
            let radii = radiusFor(module: module)
            
            ZStack {
                (state == .expanded ? module.expandedView() : module.compactView())
            }
            .frame(width: size.width, height: size.height)
            .background(
                NotchShape(
                    topCornerRadius: radii.top,
                    bottomCornerRadius: radii.bottom
                )
                .fill(.black)
                .stroke(.black, lineWidth: 1)
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: state)
            .onTapGesture {
                if module.isInteractive {
                    toggle()
                }
            }
        }
    }
    
    private func toggle() {
        switch state {
        case .compact:
            state = .expanded
        case .expanded:
            state = .intermediate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                state = .compact
            }
        case .intermediate:
            break
        }
    }
}

extension NotchContainer {
    func sizeFor(module: any NotchModule) -> CGSize {
        switch state {
        case .compact: return module.compactSize()
        case .expanded: return module.expandedSize()
        case .intermediate: return module.intermediateSize()
        }
    }
    
    func radiusFor(module: any NotchModule) -> (top: CGFloat, bottom: CGFloat) {
        switch state {
        case .compact: return module.compactRadius()
        case .expanded: return module.expandedRadius()
        case .intermediate: return module.intermediateRadius()
        }
    }
}

#Preview {
    ContentView()
}
