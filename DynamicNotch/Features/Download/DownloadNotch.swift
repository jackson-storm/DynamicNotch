import SwiftUI

struct DownloadNotchContent: NotchContentProtocol {
    let id = "download.active"
    let downloadViewModel: DownloadViewModel
    
    var priority: Int { 82 }
    var strokeColor: Color { .accentColor.opacity(0.30) }
    var offsetXTransition: CGFloat { -60 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 70, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(DownloadNotchView(downloadViewModel: downloadViewModel))
    }
}

private struct DownloadNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var downloadViewModel: DownloadViewModel
    
    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    private var download: DownloadModel? {
        downloadViewModel.primaryDownload
    }
    
    private var resolvedFileName: String {
        download?.displayName ?? "Incoming File"
    }
    
    private var trailingLabel: String {
        let extraCount = downloadViewModel.additionalDownloadCount
        
        if extraCount > 0 {
            return "+\(extraCount)"
        }
        
        return download?.directoryName ?? "Files"
    }
    
    private var sizeLabel: String {
        guard let download else { return "--" }
        return Self.byteCountFormatter.string(fromByteCount: download.byteCount)
    }
    
    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.accentColor)
                    .frame(width: 24, height: 24)
                
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            DownloadActivityIndicator(progress: download?.progress ?? 0.08)
        }
        .padding(.horizontal, 14.scaled(by: scale))
    }
}

private struct DownloadActivityIndicator: View {
    let progress: Double
    
    private enum Metrics {
        static let size: CGFloat = 18
        static let lineWidth: CGFloat = 3
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor.opacity(0.16), lineWidth: Metrics.lineWidth)
            
            Circle()
                .trim(from: 0, to: max(0.06, min(progress, 1)))
                .stroke(
                    AngularGradient(
                        colors: [
                            .accentColor.opacity(0.35),
                            .accentColor.opacity(0.9),
                            .accentColor
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(
                        lineWidth: Metrics.lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: Metrics.size, height: Metrics.size)
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
}
