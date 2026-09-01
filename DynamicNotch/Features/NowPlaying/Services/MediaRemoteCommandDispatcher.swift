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

            self.sendDirectFallbackIfUseful(for: command)

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

    private func sendDirectFallbackIfUseful(for command: NowPlayingCommand) {
        guard case .seek(let position) = command else { return }
        directDispatcher.seek(to: position)
    }
}

private final class MediaRemoteDirectCommandDispatcher {
    typealias SetElapsedTimeFunction = @convention(c) (Double) -> Void

    private let setElapsedTimeFunction: SetElapsedTimeFunction?

    init() {
        guard
            let bundle = CFBundleCreate(
                kCFAllocatorDefault,
                NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
            ),
            let pointer = CFBundleGetFunctionPointerForName(
                bundle,
                "MRMediaRemoteSetElapsedTime" as CFString
            )
        else {
            setElapsedTimeFunction = nil
            return
        }

        setElapsedTimeFunction = unsafeBitCast(
            pointer,
            to: SetElapsedTimeFunction.self
        )
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
