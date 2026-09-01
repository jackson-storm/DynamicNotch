import Foundation

enum NowPlayingCommand: Equatable {
    case play
    case pause
    case togglePlayPause
    case nextTrack
    case previousTrack
    case seek(TimeInterval)
    case setShuffle(Bool)
    case setRepeatMode(NowPlayingRepeatMode)
    case setVolume(Double)
    case setFavorite(Bool)
}
