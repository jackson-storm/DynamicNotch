import SwiftUI

struct ScreenRecordingResultNotchView: View {
    @ObservedObject var viewModel: ScreenRecordingResultViewModel
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @State private var isHovering: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            recordingPreview
        }
        .onHover { hovering in
            withAnimation(.spring(duration: 0.4)) {
                isHovering = hovering
            }
        }
        .padding(.horizontal, isDynamicIsland ? 10 : 36)
        .padding(.bottom, isDynamicIsland ? 10 : 10)
    }
    
    private var recordingPreview: some View {
        VStack {
            if let result = viewModel.activeResult {
                ZStack(alignment: .topTrailing) {
                    Button(action: {
                        viewModel.openVideo()
                    }) {
                        Color.clear
                            .frame(height: 145)
                            .overlay(
                                ZStack {
                                    Image(nsImage: result.thumbnail)
                                        .resizable()
                                        .interpolation(.high)
                                        .antialiased(true)
                                        .scaledToFill()
                                    
                                    Button(action: viewModel.openVideo) {
                                        ZStack {
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .frame(width: 45, height: 45)
                                            
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundStyle(Color.white)
                                                .offset(x: 1.5)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .blur(radius: isHovering ? 0 : 6)
                                    .opacity(isHovering ? 1 : 0)
                                    .allowsHitTesting(isHovering)
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .buttonStyle(.plain)
                    .onDrag {
                        viewModel.markAsDropped()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            viewModel.dismiss()
                        }
                        return viewModel.makeItemProvider(for: result)
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
            Button(action: { viewModel.deleteVideo() }) {
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
            
            Button(action: { viewModel.copyToClipboard() }) {
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
            
            Button(action: { viewModel.showInFinder() }) {
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
