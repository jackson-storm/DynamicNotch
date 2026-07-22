import SwiftUI

struct ScreenRecordingExpandedNotchView: View {
    @ObservedObject var viewModel: ScreenRecordingViewModel
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @State private var isBlinking = false

    var body: some View {
        VStack {
            Spacer()
            
            HStack() {
                rightContent
                Spacer()
                leftContent
            }
        }
        .padding(.leading, isDynamicIsland ? 24 : 44)
        .padding(.trailing, isDynamicIsland ? 14 : 34)
        .padding(.bottom, isDynamicIsland ? 15 : 14)
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                isBlinking = true
            }
        }
        .onDisappear {
            isBlinking = false
        }
    }
    
    private var rightContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 14, height: 14)
                    .opacity(isBlinking ? 0.4 : 1.0)

                Text(viewModel.formattedDuration)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.red)
            }
            
            Text(verbatim: "Screen Recording")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
    
    private var leftContent: some View {
        Button(action: {
            viewModel.stopRecording()
        }) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 46, height: 46)

                Circle()
                    .stroke(Color.white, lineWidth: 2.5)
                    .frame(width: 46, height: 46)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 1.0, green: 0.23, blue: 0.19))
                    .frame(width: 18, height: 18)
            }
        }
        .buttonStyle(.plain)
    }
}
