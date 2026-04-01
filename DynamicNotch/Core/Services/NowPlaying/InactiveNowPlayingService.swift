final class InactiveNowPlayingService: NowPlayingMonitoring {
    var onSnapshotChange: ((NowPlayingSnapshot?) -> Void)?

    func startMonitoring() {
        onSnapshotChange?(nil)
    }

    func stopMonitoring() {}

    func send(_ command: NowPlayingCommand) {}
}
