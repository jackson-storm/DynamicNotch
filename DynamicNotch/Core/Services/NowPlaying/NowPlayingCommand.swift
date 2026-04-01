import Foundation

enum NowPlayingCommand: Equatable {
    case togglePlayPause
    case nextTrack
    case previousTrack
    case seek(TimeInterval)
}
