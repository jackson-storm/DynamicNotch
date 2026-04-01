import Foundation

final class MediaRemoteCommandDispatcher {
    private typealias MRMediaRemoteSendCommandFunction = @convention(c) (Int, AnyObject?) -> Void

    private static let frameworkURL = URL(
        fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"
    ) as CFURL

    private let sendCommand: MRMediaRemoteSendCommandFunction?
    private let fallbackDispatcher = MediaKeyCommandDispatcher()

    init() {
        guard
            let bundle = CFBundleCreate(kCFAllocatorDefault, Self.frameworkURL),
            CFBundleLoadExecutable(bundle),
            let functionPointer = CFBundleGetFunctionPointerForName(
                bundle,
                "MRMediaRemoteSendCommand" as CFString
            )
        else {
            sendCommand = nil
            return
        }

        sendCommand = unsafeBitCast(
            functionPointer,
            to: MRMediaRemoteSendCommandFunction.self
        )
    }

    func send(_ command: NowPlayingCommand) {
        guard let commandID = mediaRemoteCommandID(for: command) else {
            fallbackDispatcher.send(command)
            return
        }

        guard let sendCommand else {
            fallbackDispatcher.send(command)
            return
        }

        sendCommand(commandID, nil)
    }

    private func mediaRemoteCommandID(for command: NowPlayingCommand) -> Int? {
        switch command {
        case .togglePlayPause:
            return 2
        case .nextTrack:
            return 4
        case .previousTrack:
            return 5
        case .seek:
            return nil
        }
    }
}
