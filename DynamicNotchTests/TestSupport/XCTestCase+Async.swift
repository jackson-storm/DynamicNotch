import XCTest

extension XCTestCase {
    func assertEventually(
        timeout: TimeInterval = 1.0,
        interval: TimeInterval = 0.01,
        _ condition: @escaping @Sendable () async -> Bool,
        message: @autoclosure () -> String = "Condition was not satisfied in time.",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if await condition() {
                return
            }

            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }

        XCTFail(message(), file: file, line: line)
    }
}
