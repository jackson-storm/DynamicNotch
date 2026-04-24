import SwiftUI
internal import AppKit

enum NowPlayingEvent: Equatable {
    case started
    case stopped
    case playbackStateChanged(isPlaying: Bool)
}

struct NowPlayingNotchContent: NotchContentProtocol {
    let id = "nowPlaying"
    
    let nowPlayingViewModel: NowPlayingViewModel
    let settings: MediaAndFilesSettingsStore
    let applicationSettings: ApplicationSettingsStore
    
    var priority: Int { 81 }
    var isExpandable: Bool { true }

    var strokeColor: Color {
        guard settings.isNowPlayingArtworkStrokeEnabled,
              applicationSettings.isDefaultActivityStrokeEnabled == false else {
            return .white.opacity(0.2)
        }
        return Color(nsColor: nowPlayingViewModel.artworkPalette.equalizerBaseColor).opacity(0.4)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 70, height: baseHeight)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 200, height: baseHeight + 160)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 34, bottom: 44)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(
            NowPlayingMinimalNotchView(
                nowPlayingViewModel: nowPlayingViewModel,
                settings: settings
            )
        )
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            NowPlayingExpandedNotchView(
                nowPlayingViewModel: nowPlayingViewModel,
                settings: settings,
                applicationSettings: applicationSettings
            )
        )
    }
}
