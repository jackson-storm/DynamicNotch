import SwiftUI

struct ScreenshotNotchView: View {
    @ObservedObject var screenshotViewModel: ScreenshotViewModel
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @Environment(\.locale) private var locale
    
    var body: some View {
        VStack {
            HStack {
                leftContent
                Spacer()
                screenshotPreview
            }
            .padding(.horizontal, 10)
            
            buttons
        }
        .padding(.top, isNotchlessScreen ? 10 : 25)
        .padding(.horizontal, isNotchlessScreen ? 15 : 40)
    }
    
    private var leftContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 18))
                    .foregroundStyle(.gray)

                Text(locale.dn("notch.screenshot.title", fallback: "Screenshot"))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.gray)
            }
            Text(locale.dnFormat("notch.screenshot.savedTo", fallback: "Saved to \"%@\"", screenshotViewModel.savedLocation))
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
    
    private var screenshotPreview: some View {
        VStack {
            if let screenshot = screenshotViewModel.activeScreenshot {
                ZStack(alignment: .topTrailing) {
                    Button(action: {
                        screenshotViewModel.openEditingWindow()
                    }) {
                        Color.clear
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(nsImage: screenshot.image)
                                    .resizable()
                                    .interpolation(.high)
                                    .antialiased(true)
                                    .scaledToFill()
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .onDrag {
                        screenshotViewModel.markAsDropped()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            screenshotViewModel.dismiss()
                        }
                        return screenshotViewModel.makeItemProvider(for: screenshot)
                    }
                }
            }
        }
    }
    
    private var buttons: some View {
        HStack {
            Button(action: { screenshotViewModel.copyImageToClipboard() }) {
                Text(locale.dn("notch.action.copy", fallback: "Copy"))
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .gray.opacity(0.25)))
            
            Button(action: { screenshotViewModel.deleteScreenshot() }) {
                Text(locale.dn("notch.action.delete", fallback: "Delete"))
                    .fontWeight(.medium)
                    .foregroundStyle(.red)
            }
            .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .red.opacity(0.25)))
        }
    }
}
