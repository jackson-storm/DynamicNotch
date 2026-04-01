import Foundation

final class MediaRemoteElapsedTimeDispatcher {
    private typealias MRMediaRemoteSetElapsedTimeFunction = @convention(c) (Double) -> Void

    private static let frameworkURL = URL(
        fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"
    ) as CFURL

    private let setElapsedTime: MRMediaRemoteSetElapsedTimeFunction?

    init() {
        guard
            let bundle = CFBundleCreate(kCFAllocatorDefault, Self.frameworkURL),
            CFBundleLoadExecutable(bundle),
            let functionPointer = CFBundleGetFunctionPointerForName(
                bundle,
                "MRMediaRemoteSetElapsedTime" as CFString
            )
        else {
            setElapsedTime = nil
            return
        }

        setElapsedTime = unsafeBitCast(
            functionPointer,
            to: MRMediaRemoteSetElapsedTimeFunction.self
        )
    }

    func seek(to position: TimeInterval) {
        guard position.isFinite else { return }
        setElapsedTime?(max(0, position))
    }
}
