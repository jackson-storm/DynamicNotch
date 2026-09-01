protocol NowPlayingMonitoring: AnyObject {
    var onSnapshotChange: ((NowPlayingSnapshot?) -> Void)? { get set }

    func startMonitoring()
    func stopMonitoring()
    func send(_ command: NowPlayingCommand)
}

protocol NowPlayingDetailPollingConfigurable: AnyObject {
    func setDetailPollingEnabled(_ isEnabled: Bool)
}
