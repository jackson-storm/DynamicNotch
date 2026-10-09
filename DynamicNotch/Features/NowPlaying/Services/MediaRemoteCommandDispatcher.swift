import Foundation

final class MediaRemoteCommandDispatcher {
    private static let perlExecutableURL = URL(fileURLWithPath: "/usr/bin/perl")
    private static let microsecondsPerSecond: Double = 1_000_000

    private let commandQueue = DispatchQueue(
        label: "com.dynamicnotch.mediaremote.adapter.commands",
        qos: .userInitiated
    )
    private let resourcesProvider: () -> MediaRemoteAdapterResources?
    private let fallbackDispatcher = MediaKeyCommandDispatcher()
    private let directDispatcher = MediaRemoteDirectCommandDispatcher()

    init(resourcesProvider: @escaping () -> MediaRemoteAdapterResources? = {
        MediaRemoteAdapterResources.resolve()
    }) {
        self.resourcesProvider = resourcesProvider
    }

    func send(_ command: NowPlayingCommand) {
        commandQueue.async { [weak self] in
            guard let self else { return }

            if self.directDispatcher.send(command) {
                return
            }

            guard let adapterArguments = self.adapterArguments(for: command) else {
                self.sendFallbackIfAvailable(for: command)
                return
            }

            guard self.runAdapter(with: adapterArguments) else {
                self.sendFallbackIfAvailable(for: command)
                return
            }
        }
    }

    private func adapterArguments(for command: NowPlayingCommand) -> [String]? {
        switch command {
        case .play:
            return ["send", "0"]
        case .pause:
            return ["send", "1"]
        case .togglePlayPause:
            return ["send", "2"]
        case .nextTrack:
            return ["send", "4"]
        case .previousTrack:
            return ["send", "5"]
        case .seek(let position):
            guard position.isFinite else { return nil }
            let microseconds = Int64((max(0, position) * Self.microsecondsPerSecond).rounded())
            return ["seek", String(microseconds)]
        case .setShuffle(let isEnabled):
            return ["shuffle", isEnabled ? "3" : "1"]
        case .setRepeatMode(let repeatMode):
            return ["repeat", String(repeatMode.rawValue)]
        case .setVolume, .setFavorite:
            return nil
        }
    }

    private func runAdapter(with commandArguments: [String]) -> Bool {
        guard let resources = resourcesProvider() else { return false }

        let process = Process()
        process.executableURL = Self.perlExecutableURL
        process.arguments = resources.invocationArguments(for: commandArguments)
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func sendFallbackIfAvailable(for command: NowPlayingCommand) {
        guard command.usesMediaKeyFallback else { return }

        DispatchQueue.main.async { [fallbackDispatcher] in
            fallbackDispatcher.send(command)
        }
    }
}

private final class MediaRemoteDirectCommandDispatcher {
    typealias SendCommandFunction = @convention(c) (Int32, AnyObject?) -> DarwinBoolean
    typealias SetElapsedTimeFunction = @convention(c) (Double) -> Void
    typealias SetShuffleModeFunction = @convention(c) (Int32) -> Void
    typealias SetRepeatModeFunction = @convention(c) (Int32) -> Void

    private let sendCommandFunction: SendCommandFunction?
    private let setElapsedTimeFunction: SetElapsedTimeFunction?
    private let setShuffleModeFunction: SetShuffleModeFunction?
    private let setRepeatModeFunction: SetRepeatModeFunction?

    init() {
        guard
            let bundle = CFBundleCreate(
                kCFAllocatorDefault,
                NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
            )
        else {
            sendCommandFunction = nil
            setElapsedTimeFunction = nil
            setShuffleModeFunction = nil
            setRepeatModeFunction = nil
            return
        }

        if let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString) {
            sendCommandFunction = unsafeBitCast(pointer, to: SendCommandFunction.self)
        } else {
            sendCommandFunction = nil
        }

        if let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSetElapsedTime" as CFString) {
            setElapsedTimeFunction = unsafeBitCast(pointer, to: SetElapsedTimeFunction.self)
        } else {
            setElapsedTimeFunction = nil
        }

        if let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSetShuffleMode" as CFString) {
            setShuffleModeFunction = unsafeBitCast(pointer, to: SetShuffleModeFunction.self)
        } else {
            setShuffleModeFunction = nil
        }

        if let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSetRepeatMode" as CFString) {
            setRepeatModeFunction = unsafeBitCast(pointer, to: SetRepeatModeFunction.self)
        } else {
            setRepeatModeFunction = nil
        }
    }

    func send(_ command: NowPlayingCommand) -> Bool {
        switch command {
        case .play:
            guard let sendCommandFunction else { return false }
            return sendCommandFunction(0, nil).boolValue
        case .pause:
            guard let sendCommandFunction else { return false }
            return sendCommandFunction(1, nil).boolValue
        case .togglePlayPause:
            guard let sendCommandFunction else { return false }
            return sendCommandFunction(2, nil).boolValue
        case .nextTrack:
            guard let sendCommandFunction else { return false }
            return sendCommandFunction(4, nil).boolValue
        case .previousTrack:
            guard let sendCommandFunction else { return false }
            return sendCommandFunction(5, nil).boolValue
        case .seek(let position):
            guard let setElapsedTimeFunction, position.isFinite else { return false }
            setElapsedTimeFunction(max(0, position))
            return true
        case .setShuffle(let isEnabled):
            guard let setShuffleModeFunction else { return false }
            setShuffleModeFunction(isEnabled ? 3 : 1)
            return true
        case .setRepeatMode(let repeatMode):
            guard let setRepeatModeFunction else { return false }
            setRepeatModeFunction(Int32(repeatMode.rawValue))
            return true
        case .setVolume, .setFavorite:
            return false
        }
    }

    func seek(to position: TimeInterval) {
        guard position.isFinite else { return }
        setElapsedTimeFunction?(max(0, position))
    }
}

private extension NowPlayingCommand {
    var usesMediaKeyFallback: Bool {
        switch self {
        case .togglePlayPause, .nextTrack, .previousTrack:
            return true
        default:
            return false
        }
    }
}
