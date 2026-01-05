import SwiftUI

struct NotchView: View {
    @ObservedObject var viewModel: NotchViewModel
    
    weak var window: NSWindow?
    
    var body: some View {
        VStack {
            ZStack {
                NotchShape(topCornerRadius: viewModel.state.cornerRadius.top, bottomCornerRadius: viewModel.state.cornerRadius.bottom)
                .fill(Color.black)
                
                content
            }
            .frame(width: viewModel.state.size.width, height: viewModel.state.size.height)
            
            controls
        }
        .onHover { hovering in
            window?.ignoresMouseEvents = !hovering
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private extension NotchView {
    @ViewBuilder
    var content: some View {
        Group {
            switch viewModel.state.content {
            case .none:
                EmptyView()
                
            case .music:
                Text("Music")
                
            case .notification:
                Text("Notification")
                
            case .charger:
                ChargerNotch(powerSourceMonitor: PowerSourceMonitor())
            }
        }
        .id(viewModel.state.content)
        .transition(.blurAndFade.animation(.spring(duration: 0.5)).combined(with: .scale))
    }
}

private extension NotchView {
    var controls: some View {
        HStack(spacing: 15) {
            Button("Charger") {
                viewModel.send(.show(.charger))
            }
            Button("Music") {
                viewModel.send(.show(.music))
            }
            Button("Notification") {
                viewModel.send(.show(.notification))
            }
            Button("Hide") {
                viewModel.send(.hide)
            }
        }
        .padding()
    }
}
