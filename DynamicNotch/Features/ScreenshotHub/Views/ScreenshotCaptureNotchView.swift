import SwiftUI
internal import AppKit

struct ScreenshotCaptureNotchView: View {
    @ObservedObject var model: ScreenshotCaptureModel
    let onCapture: (ScreenshotCaptureModel.Mode) -> Void
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                captureButton(.display, title: "homeTools.capture.display", icon: "rectangle.inset.filled")
                captureButton(.region, title: "homeTools.capture.region", icon: "viewfinder")
            }
            HStack(spacing: 5) {
                Image(systemName: model.didCopy ? "checkmark.circle.fill" : "doc.on.clipboard")
                Text(model.didCopy ? LocalizedStringKey("homeTools.capture.copied") : LocalizedStringKey("homeTools.capture.hint"))
            }
            .font(.system(size: 11))
            .foregroundStyle(model.didCopy ? Color.green : Color.white.opacity(0.55))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, isNotchlessScreen ? 20 : 40)
        .padding(.bottom, 18)
    }

    private func captureButton(_ mode: ScreenshotCaptureModel.Mode, title: LocalizedStringKey, icon: String) -> some View {
        Button {
            onCapture(mode)
        } label: {
            VStack(spacing: 9) {
                Image(systemName: icon).font(.system(size: 24, weight: .regular))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 78)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(ScreenshotTileStyle())
        .disabled(model.isCapturing)
        .accessibilityLabel(Text(title))
    }
}

private struct ScreenshotTileStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.65 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
