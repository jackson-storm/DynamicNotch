import SwiftUI

struct ScreenshotNotchView: View {
    @ObservedObject var screenshotViewModel: ScreenshotViewModel
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @State private var isHovering: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            screenshot
        }
        .onHover { hovering in
            withAnimation(.spring(duration: 0.4)) {
                isHovering = hovering
            }
        }
        .padding(.horizontal, isDynamicIsland ? 10 : 36)
        .padding(.bottom, isDynamicIsland ? 10 : 10)
    }
    
    private var screenshot: some View {
        VStack {
            if let screenshot = screenshotViewModel.activeScreenshot {
                ZStack(alignment: .topTrailing) {
                    Button(action: {
                        screenshotViewModel.openEditingWindow()
                    }) {
                        Color.clear
                            .frame(height: 145)
                            .overlay(
                                Image(nsImage: screenshot.image)
                                    .resizable()
                                    .interpolation(.high)
                                    .antialiased(true)
                                    .scaledToFill()
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .buttonStyle(.plain)
                    .onDrag {
                        screenshotViewModel.markAsDropped()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            screenshotViewModel.dismiss()
                        }
                        return screenshotViewModel.makeItemProvider(for: screenshot)
                    }
                    
                    buttons
                        .blur(radius: isHovering ? 0 : 6)
                        .opacity(isHovering ? 1 : 0)
                        .allowsHitTesting(isHovering)
                }
            }
        }
    }
    
    private var buttons: some View {
        VStack(spacing: 10) {
            Button(action: { screenshotViewModel.deleteScreenshot() }) {
                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .stroke(.white.opacity(0.08))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white)
                }
            }
            
            Button(action: { screenshotViewModel.copyImageToClipboard() }) {
                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .stroke(.white.opacity(0.08))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "document.on.document.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white)
                }
            }
            
            Button(action: { screenshotViewModel.showInFinder() }) {
                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .stroke(.white.opacity(0.08))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white)
                }
            }
        }
        .padding(8)
        .buttonStyle(.plain)
    }
}
