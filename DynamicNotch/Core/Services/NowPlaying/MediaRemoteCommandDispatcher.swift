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

    init(resourcesProvider: @escaping () -> MediaRemoteAdapterResources? = {
        MediaRemoteAdapterResources.resolve()
    }) {
        self.resourcesProvider = resourcesProvider
    }

    func send(_ command: NowPlayingCommand) {
        commandQueue.async { [weak self] in
            guard let self else { return }

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
        guard !command.isSeek else { return }

        DispatchQueue.main.async { [fallbackDispatcher] in
            fallbackDispatcher.send(command)
        }
    }
}

private extension NowPlayingCommand {
    var isSeek: Bool {
        if case .seek = self {
            return true
        }
        return false
    }
}
