import SwiftUI

struct ScreenshotNotchView: View {
    @ObservedObject var screenshotViewModel: ScreenshotViewModel
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    
    var body: some View {
        VStack {
            Spacer()
            screenshot
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
                    
                    HStack {
                        Button(action: {
                            screenshotViewModel.showInFinder()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.thickMaterial)
                                    .frame(width: 26, height: 26)
                                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                                
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.white)
                            }
                        }
                        
                        Button(action: {
                            screenshotViewModel.deleteScreenshot()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.thickMaterial)
                                    .frame(width: 26, height: 26)
                                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                                
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.white)
                            }
                        }
                    }
                    .padding(8)
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
