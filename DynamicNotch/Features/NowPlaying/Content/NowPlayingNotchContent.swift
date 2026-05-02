import SwiftUI
internal import AppKit

enum NowPlayingEvent: Equatable {
    case started
    case stopped
    case playbackStateChanged(isPlaying: Bool)
}

struct NowPlayingNotchContent: NotchContentProtocol {
    let id = NotchContentRegistry.Media.nowPlaying.id
    
    let nowPlayingViewModel: NowPlayingViewModel
    let settings: MediaAndFilesSettingsStore
    let applicationSettings: ApplicationSettingsStore
    let onOpenPlaybackSource: @MainActor () -> Void

    init(
        nowPlayingViewModel: NowPlayingViewModel,
        settings: MediaAndFilesSettingsStore,
        applicationSettings: ApplicationSettingsStore,
        onOpenPlaybackSource: @escaping @MainActor () -> Void = {}
    ) {
        self.nowPlayingViewModel = nowPlayingViewModel
        self.settings = settings
        self.applicationSettings = applicationSettings
        self.onOpenPlaybackSource = onOpenPlaybackSource
    }
    
    var priority: Int { NotchContentRegistry.Media.nowPlaying.priority }
    var isExpandable: Bool { true }

    var windowLink: (@MainActor () -> Void)? {
        guard nowPlayingViewModel.canOpenPlaybackSource else { return nil }

        return {
            nowPlayingViewModel.openPlaybackSource()
        }
    }

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
                nowPlayingViewModel: nowPlayingViewModel
            )
        )
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            NowPlayingExpandedNotchView(
                nowPlayingViewModel: nowPlayingViewModel,
                settings: settings,
                applicationSettings: applicationSettings,
                onOpenPlaybackSource: onOpenPlaybackSource
            )
        )
    }
}
