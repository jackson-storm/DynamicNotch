protocol NowPlayingMonitoring: AnyObject {
    var onSnapshotChange: ((NowPlayingSnapshot?) -> Void)? { get set }

    func startMonitoring()
    func stopMonitoring()
    func send(_ command: NowPlayingCommand)
}
