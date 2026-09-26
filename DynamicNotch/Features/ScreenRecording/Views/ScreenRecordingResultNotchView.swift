import SwiftUI

struct ScreenRecordingResultNotchView: View {
    @ObservedObject var viewModel: ScreenRecordingResultViewModel
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                rightContent
                Spacer()
                recordingPreview
            }
            .padding(.horizontal, 10)
            
            buttons
        }
        .padding(.horizontal, isNotchlessScreen ? 10 : 40)
        .padding(.bottom, isNotchlessScreen ? 10 : 10)
    }
    
    private var rightContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 14, height: 14)

                Text(viewModel.formattedDuration)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.red)
            }
            Text(verbatim: "Saved to \"\(viewModel.savedLocation)\"")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
    
    private var recordingPreview: some View {
        VStack {
            if let result = viewModel.activeResult {
                ZStack(alignment: .topTrailing) {
                    Button(action: {
                        viewModel.openVideo()
                    }) {
                        Color.clear
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(nsImage: result.thumbnail)
                                    .resizable()
                                    .interpolation(.high)
                                    .antialiased(true)
                                    .scaledToFill()
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var buttons: some View {
        HStack {
            Button(action: { viewModel.openVideo() }) {
                Text(verbatim: "Watch")
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .gray.opacity(0.25)))
            
            Button(action: { viewModel.deleteVideo() }) {
                Text(verbatim: "Delete")
                    .fontWeight(.medium)
                    .foregroundStyle(.red)
            }
            .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .red.opacity(0.25)))
        }
    }
}
