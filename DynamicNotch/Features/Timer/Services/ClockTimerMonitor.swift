import Foundation
internal import AppKit
#if canImport(ApplicationServices)
import ApplicationServices
#endif
import OSLog

final class ClockTimerMonitor: ClockTimerMonitoring {
    var onSnapshotChange: ((ClockTimerSnapshot?) -> Void)?

    private let logger = Logger(subsystem: "com.dynamicnotch.app", category: "ClockTimerMonitor")
    private let metadataDomain: CFString
    private let metadataFilePath: String
    private let fallbackPollInterval: TimeInterval
    private let dateProvider: () -> Date
    private let queue: DispatchQueue

    private var preferencesTimer: PreferencesTimer?
    private var trackedTimerID: String?
    private var preferredTitle: String?
    private var preferredDuration: TimeInterval?
    private var totalDurationHint: TimeInterval?
    private var currentRemaining: TimeInterval?
    private var currentPausedState = false
    private var lastPublishedSnapshot: ClockTimerSnapshot?

    private var logProcess: Process?
    private var logPipe: Pipe?
    private var logBuffer = Data()
    private var logRestartWorkItem: DispatchWorkItem?
    private var completionClearWorkItem: DispatchWorkItem?

    private var fileDescriptor: CInt = -1
    private var fileMonitor: DispatchSourceFileSystemObject?
    private var accessibilityTicker: DispatchSourceTimer?
    private var didWarnAboutAccessibility = false

    #if canImport(ApplicationServices)
    private var menuBarTimerItem: AXUIElement?
    #endif

    init(
        metadataDomain: CFString = "com.apple.mobiletimerd" as CFString,
        metadataFilePath: String = (NSHomeDirectory() as NSString)
            .appendingPathComponent("Library/Preferences/com.apple.mobiletimerd.plist"),
        fallbackPollInterval: TimeInterval = 1,
        dateProvider: @escaping () -> Date = Date.init,
        queue: DispatchQueue = DispatchQueue(
            label: "com.dynamicnotch.clock-timer-monitor",
            qos: .userInitiated
        )
    ) {
        self.metadataDomain = metadataDomain
        self.metadataFilePath = metadataFilePath
        self.fallbackPollInterval = fallbackPollInterval
        self.dateProvider = dateProvider
        self.queue = queue
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        queue.async { [weak self] in
            guard let self, !self.isMonitoring else { return }

            self.reloadPreferencesTimer()
            self.startPreferencesMonitor()

            let logStarted = self.startLogStream()

            #if canImport(ApplicationServices)
            let hasAccessibility = AXIsProcessTrusted()
            #else
            let hasAccessibility = false
            #endif

            if !logStarted {
                if hasAccessibility {
                    self.startAccessibilityFallbackIfPossible()
                } else {
                    self.postAccessibilityWarningIfNeeded()
                }
            } else if !hasAccessibility {
                self.postAccessibilityWarningIfNeeded()
            }
        }
    }

    func stopMonitoring() {
        queue.async { [weak self] in
            self?.teardown(clearSnapshot: false)
        }
    }
}

private extension ClockTimerMonitor {
    struct PreferencesTimer: Equatable {
        enum State: Int {
            case unknown = 0
            case stopped = 1
            case running = 2
            case paused = 3
            case fired = 4

            var isActive: Bool {
                self == .running || self == .paused
            }
        }

        let identifier: String
        let title: String
        let duration: TimeInterval
        let state: State
        let lastModified: Date?
    }

    struct LoggedTimerSummary {
        let identifier: String
        let state: PreferencesTimer.State?
        let title: String?
        let duration: TimeInterval?
    }

    #if canImport(ApplicationServices)
    struct MenuBarTimerSample {
        let remaining: TimeInterval
        let isPaused: Bool
    }
    #endif

    var isMonitoring: Bool {
        logProcess != nil || fileMonitor != nil || accessibilityTicker != nil
    }

    func teardown(clearSnapshot: Bool) {
        logRestartWorkItem?.cancel()
        logRestartWorkItem = nil
        completionClearWorkItem?.cancel()
        completionClearWorkItem = nil

        stopLogStream()

        accessibilityTicker?.setEventHandler {}
        accessibilityTicker?.cancel()
        accessibilityTicker = nil

        fileMonitor?.setEventHandler {}
        fileMonitor?.cancel()
        fileMonitor = nil

        if fileDescriptor != -1 {
            close(fileDescriptor)
            fileDescriptor = -1
        }

        #if canImport(ApplicationServices)
        menuBarTimerItem = nil
        #endif

        preferencesTimer = nil
        trackedTimerID = nil
        preferredTitle = nil
        preferredDuration = nil
        totalDurationHint = nil
        currentRemaining = nil
        currentPausedState = false

        if clearSnapshot {
            publish(snapshot: nil)
        }
    }

    func startPreferencesMonitor() {
        guard fileMonitor == nil else { return }

        let descriptor = open(metadataFilePath, O_EVTONLY)
        guard descriptor != -1 else {
            logger.debug("Timer preferences file is not available at \(self.metadataFilePath, privacy: .public)")
            return
        }

        fileDescriptor = descriptor

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .rename, .attrib],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            self?.reloadPreferencesTimer()
        }

        source.resume()
        fileMonitor = source
    }

    @discardableResult
    func startLogStream() -> Bool {
        if let logProcess, logProcess.isRunning {
            return true
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        process.arguments = [
            "stream",
            "--style",
            "ndjson",
            "--predicate",
            "subsystem == \"com.apple.mobiletimer.logging\"",
            "--level",
            "debug"
        ]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }

            self?.queue.async { [weak self] in
                self?.consumeLogData(data)
            }
        }

        process.terminationHandler = { [weak self] _ in
            self?.queue.async { [weak self] in
                self?.handleLogStreamTermination()
            }
        }

        do {
            try process.run()
            logPipe = outputPipe
            logProcess = process
            logBuffer.removeAll(keepingCapacity: false)
            logger.debug("Started Clock log stream with pid \(process.processIdentifier, privacy: .public)")
            return true
        } catch {
            outputPipe.fileHandleForReading.readabilityHandler = nil
            logPipe = nil
            logger.error("Failed to start Clock log stream: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func stopLogStream() {
        logPipe?.fileHandleForReading.readabilityHandler = nil
        logPipe?.fileHandleForReading.closeFile()
        logPipe = nil

        if let logProcess {
            logProcess.terminationHandler = nil
            if logProcess.isRunning {
                logProcess.terminate()
                logProcess.waitUntilExit()
            }
        }

        logProcess = nil
        logBuffer.removeAll(keepingCapacity: false)
    }

    func handleLogStreamTermination() {
        logPipe?.fileHandleForReading.readabilityHandler = nil
        logPipe?.fileHandleForReading.closeFile()
        logPipe = nil
        logProcess = nil
        logBuffer.removeAll(keepingCapacity: false)

        startAccessibilityFallbackIfPossible()
        scheduleLogRestart()
    }

    func scheduleLogRestart() {
        logRestartWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.logRestartWorkItem = nil

            let logStarted = self.startLogStream()
            if !logStarted {
                self.startAccessibilityFallbackIfPossible()
            }
        }

        logRestartWorkItem = workItem
        queue.asyncAfter(deadline: .now() + 2, execute: workItem)
    }

    func consumeLogData(_ data: Data) {
        logBuffer.append(data)

        while let newlineIndex = logBuffer.firstIndex(of: 0x0A) {
            let line = Data(logBuffer[..<newlineIndex])
            let removalIndex = logBuffer.index(after: newlineIndex)
            logBuffer.removeSubrange(..<removalIndex)

            guard !line.isEmpty else { continue }
            processLogLine(line)
        }
    }

    func processLogLine(_ line: Data) {
        guard
            let payload = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
            let message = payload["eventMessage"] as? String,
            !message.isEmpty
        else {
            return
        }

        processLogMessage(message)
    }

    func processLogMessage(_ message: String) {
        if message.contains("scheduled timers:") {
            applyScheduledTimersMessage(message)
        }

        if message.contains("started timer:") {
            applyStartedTimerMessage(message)
        }

        if message.contains("next timer changed:") {
            applyNextTimerChangedMessage(message)
        }

        if message.contains("Timer will fire") {
            applyWillFireMessage(message)
        }

        if message.contains("remainingTime:") {
            applyRemainingTimeMessage(message)
        }

        if message.contains("Timer stopped") {
            handleTimerStoppedMessage()
        }
    }

    func applyScheduledTimersMessage(_ message: String) {
        let timers = parseLoggedTimers(from: message)
        guard !timers.isEmpty else { return }

        let trackedID = trackedTimerID?.uppercased()
        let selectedTimer: LoggedTimerSummary?

        if let trackedID {
            selectedTimer = timers.first(where: { $0.identifier == trackedID }) ??
                timers.first(where: { $0.state?.isActive == true })
        } else {
            selectedTimer = timers.first(where: { $0.state?.isActive == true }) ??
                timers.first(where: { $0.state == .fired })
        }

        guard let selectedTimer else { return }

        if trackedID == nil || trackedID != selectedTimer.identifier {
            beginTracking(timerID: selectedTimer.identifier)
        }

        if let title = selectedTimer.title?.trimmingCharacters(in: .whitespacesAndNewlines),
           !title.isEmpty,
           title != "(null)" {
            preferredTitle = title
        }

        if let duration = selectedTimer.duration, duration > 0 {
            preferredDuration = max(preferredDuration ?? 0, duration)
            totalDurationHint = max(totalDurationHint ?? 0, duration)
        }

        guard let state = selectedTimer.state else { return }

        switch state {
        case .paused:
            if let currentRemaining {
                applyLogDrivenUpdate(remaining: currentRemaining, paused: true)
            } else {
                currentPausedState = true
            }

        case .running:
            if let currentRemaining {
                applyLogDrivenUpdate(remaining: currentRemaining, paused: false)
            } else {
                currentPausedState = false
            }

        case .fired:
            applyLogDrivenUpdate(remaining: 0, paused: false)

        case .stopped:
            if completionClearWorkItem == nil {
                handleTimerStoppedMessage()
            }

        case .unknown:
            break
        }
    }

    func applyStartedTimerMessage(_ message: String) {
        guard let identifier = firstMatch(pattern: "started timer:\\s*([A-Fa-f0-9\\-]+)", in: message) else {
            return
        }

        beginTracking(timerID: identifier)
        if preferencesTimer?.state == .paused {
            currentPausedState = true
        } else {
            currentPausedState = false
        }
    }

    func applyNextTimerChangedMessage(_ message: String) {
        guard let token = firstMatch(pattern: "next timer changed:\\s*([^\n]+)", in: message) else {
            return
        }

        let cleanedToken = token.trimmingCharacters(in: CharacterSet(charactersIn: " <>"))
        guard !cleanedToken.isEmpty else { return }

        if cleanedToken.lowercased().contains("null") {
            if preferencesTimer?.state.isActive != true {
                clearTrackedTimer()
            }
            return
        }

        beginTracking(timerID: cleanedToken)
    }

    func applyWillFireMessage(_ message: String) {
        guard let minutesToken = firstMatch(pattern: "Timer will fire\\s+([0-9.]+)\\s+minutes?", in: message),
              let minutes = Double(minutesToken) else {
            return
        }

        applyLogDrivenUpdate(remaining: minutes * 60, paused: currentPausedState)
    }

    func applyRemainingTimeMessage(_ message: String) {
        guard let remainingToken = firstMatch(pattern: "remainingTime:\\s*([-0-9.]+)", in: message),
              let remaining = Double(remainingToken) else {
            return
        }

        applyLogDrivenUpdate(remaining: remaining, paused: currentPausedState)
    }

    func handleTimerStoppedMessage() {
        guard trackedTimerID != nil else { return }
        guard completionClearWorkItem == nil else { return }
        clearTrackedTimer()
    }

    func applyLogDrivenUpdate(remaining: TimeInterval, paused: Bool) {
        guard trackedTimerID != nil || preferencesTimer?.state.isActive == true else { return }
        recordRemaining(remaining, paused: paused)
    }

    func recordRemaining(_ remaining: TimeInterval, paused: Bool) {
        let resolvedRemaining = max(0, remaining.rounded())
        var resolvedPaused = paused

        if let previousRemaining = currentRemaining,
           paused,
           (previousRemaining - resolvedRemaining) > 0.75 {
            resolvedPaused = false
        }

        if preferencesTimer?.state == .running {
            resolvedPaused = false
        } else if preferencesTimer?.state == .paused {
            resolvedPaused = true
        }

        currentRemaining = resolvedRemaining
        currentPausedState = resolvedPaused

        if resolvedRemaining <= 0 {
            publishCurrentSnapshot()
            scheduleCompletionClear()
            return
        }

        cancelCompletionClear()
        publishCurrentSnapshot()
    }

    func publishCurrentSnapshot() {
        guard let currentRemaining else {
            publish(snapshot: nil)
            return
        }

        let title = resolvedTitle()
        let identifier = trackedTimerID ?? preferencesTimer?.identifier ?? NotchContentRegistry.Media.timer.id
        let duration = resolvedDuration(for: currentRemaining)
        let now = dateProvider()
        let candidate = makeSnapshot(
            identifier: identifier,
            title: title,
            duration: duration,
            remaining: currentRemaining,
            isPaused: currentPausedState,
            now: now
        )

        publish(snapshot: stabilizedSnapshot(for: candidate, now: now))
    }

    func resolvedTitle() -> String {
        let candidates = [
            preferredTitle,
            preferencesTimer?.title
        ]

        for candidate in candidates {
            let trimmed = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        return "Timer"
    }

    func resolvedDuration(for remaining: TimeInterval) -> TimeInterval {
        let candidates = [
            totalDurationHint,
            preferredDuration,
            preferencesTimer?.duration,
            remaining
        ]

        let resolved = candidates.compactMap { $0 }.reduce(0, max)
        totalDurationHint = max(totalDurationHint ?? 0, resolved, remaining)
        return max(1, resolved)
    }

    func makeSnapshot(
        identifier: String,
        title: String,
        duration: TimeInterval,
        remaining: TimeInterval,
        isPaused: Bool,
        now: Date
    ) -> ClockTimerSnapshot {
        let roundedRemaining = max(0, remaining.rounded())
        let endDate = now.addingTimeInterval(roundedRemaining)

        return snapshot(
            identifier: identifier,
            title: title,
            duration: duration,
            endDate: endDate,
            isPaused: isPaused,
            pausedRemaining: isPaused ? roundedRemaining : nil
        )
    }

    func snapshot(
        identifier: String,
        title: String,
        duration: TimeInterval,
        endDate: Date,
        isPaused: Bool,
        pausedRemaining: TimeInterval?
    ) -> ClockTimerSnapshot {
        let roundedDuration = max(1, duration.rounded())
        let roundedPausedRemaining = pausedRemaining.map { max(0, $0.rounded()) }
        let fingerprint: String

        if isPaused {
            fingerprint = [
                identifier,
                title,
                "paused",
                String(Int((roundedPausedRemaining ?? 0).rounded())),
                String(Int(roundedDuration))
            ].joined(separator: "|")
        } else {
            fingerprint = [
                identifier,
                title,
                "running",
                String(Int(endDate.timeIntervalSince1970.rounded())),
                String(Int(roundedDuration))
            ].joined(separator: "|")
        }

        return ClockTimerSnapshot(
            identifier: identifier,
            title: title,
            duration: roundedDuration,
            endDate: endDate,
            isPaused: isPaused,
            pausedRemaining: roundedPausedRemaining,
            fingerprint: fingerprint
        )
    }

    func stabilizedSnapshot(for snapshot: ClockTimerSnapshot, now: Date) -> ClockTimerSnapshot {
        guard let lastPublishedSnapshot else {
            return snapshot
        }

        guard
            lastPublishedSnapshot.identifier == snapshot.identifier,
            lastPublishedSnapshot.title == snapshot.title
        else {
            return snapshot
        }

        if snapshot.isPaused {
            let previousRemaining = lastPublishedSnapshot.pausedRemaining ?? lastPublishedSnapshot.remainingTime(at: now)
            let currentRemaining = snapshot.pausedRemaining ?? snapshot.remainingTime(at: now)

            guard lastPublishedSnapshot.isPaused, abs(previousRemaining - currentRemaining) <= 1 else {
                return snapshot
            }

            return self.snapshot(
                identifier: snapshot.identifier,
                title: snapshot.title,
                duration: max(lastPublishedSnapshot.duration, snapshot.duration, currentRemaining),
                endDate: lastPublishedSnapshot.endDate,
                isPaused: true,
                pausedRemaining: previousRemaining
            )
        }

        guard
            !lastPublishedSnapshot.isPaused,
            abs(lastPublishedSnapshot.endDate.timeIntervalSince(snapshot.endDate)) <= 2
        else {
            return snapshot
        }

        return self.snapshot(
            identifier: snapshot.identifier,
            title: snapshot.title,
            duration: max(lastPublishedSnapshot.duration, snapshot.duration, snapshot.remainingTime(at: now)),
            endDate: lastPublishedSnapshot.endDate,
            isPaused: false,
            pausedRemaining: nil
        )
    }

    func publish(snapshot: ClockTimerSnapshot?) {
        guard snapshot != lastPublishedSnapshot else { return }
        lastPublishedSnapshot = snapshot

        DispatchQueue.main.async { [weak self] in
            self?.onSnapshotChange?(snapshot)
        }
    }

    func scheduleCompletionClear(after delay: TimeInterval = 3.2) {
        cancelCompletionClear()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.completionClearWorkItem = nil
            self.clearTrackedTimer()
        }

        completionClearWorkItem = workItem
        queue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    func cancelCompletionClear() {
        completionClearWorkItem?.cancel()
        completionClearWorkItem = nil
    }

    func beginTracking(timerID: String) {
        let normalizedID = timerID
            .trimmingCharacters(in: CharacterSet(charactersIn: " <>"))
            .uppercased()

        guard !normalizedID.isEmpty else { return }

        guard normalizedID != trackedTimerID else { return }

        trackedTimerID = normalizedID
        preferredTitle = nil
        preferredDuration = nil
        totalDurationHint = preferencesTimer?.duration
        currentRemaining = nil
        currentPausedState = preferencesTimer?.state == .paused
        cancelCompletionClear()
    }

    func clearTrackedTimer() {
        cancelCompletionClear()
        trackedTimerID = nil
        preferredTitle = nil
        preferredDuration = nil
        totalDurationHint = nil
        currentRemaining = nil
        currentPausedState = false
        publish(snapshot: nil)
    }

    func reloadPreferencesTimer() {
        let previousTimer = preferencesTimer
        preferencesTimer = loadPreferencesTimer()

        guard let preferencesTimer else {
            totalDurationHint = nil
            if trackedTimerID == nil {
                publish(snapshot: nil)
            }
            return
        }

        if trackedTimerID == nil, preferencesTimer.state.isActive {
            beginTracking(timerID: preferencesTimer.identifier)
        }

        if preferencesTimer.duration > 0 {
            totalDurationHint = max(totalDurationHint ?? 0, preferencesTimer.duration)
        }

        switch preferencesTimer.state {
        case .running:
            currentPausedState = false
            if previousTimer?.duration != preferencesTimer.duration, currentRemaining != nil {
                publishCurrentSnapshot()
            }

        case .paused:
            currentPausedState = true
            if currentRemaining != nil {
                publishCurrentSnapshot()
            }

        case .fired:
            if currentRemaining == nil {
                recordRemaining(0, paused: false)
            } else if (currentRemaining ?? 0) <= 0 {
                scheduleCompletionClear()
            }

        case .stopped:
            guard completionClearWorkItem == nil else { break }
            if currentRemaining == nil || (currentRemaining ?? 0) <= 0 {
                clearTrackedTimer()
            }

        case .unknown:
            break
        }
    }

    func loadPreferencesTimer() -> PreferencesTimer? {
        CFPreferencesAppSynchronize(metadataDomain)

        guard
            let container = CFPreferencesCopyAppValue("MTTimers" as CFString, metadataDomain) as? [String: Any],
            let rawTimers = container["MTTimers"] as? [[String: Any]]
        else {
            return nil
        }

        let timers = rawTimers.compactMap { entry -> PreferencesTimer? in
            guard let timer = entry["$MTTimer"] as? [String: Any] else { return nil }

            let identifier = timer["MTTimerID"] as? String ?? UUID().uuidString
            let rawTitle = (timer["MTTimerTitle"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = (rawTitle?.isEmpty == false) ? rawTitle! : "Timer"
            let duration = timer["MTTimerDuration"] as? TimeInterval ?? 0
            let rawState = timer["MTTimerState"] as? Int ?? 0

            return PreferencesTimer(
                identifier: identifier,
                title: title,
                duration: duration,
                state: PreferencesTimer.State(rawValue: rawState) ?? .unknown,
                lastModified: timer["MTTimerLastModifiedDate"] as? Date
            )
        }

        if let activeTimer = timers.first(where: { $0.state.isActive }) {
            return activeTimer
        }

        return timers.sorted { lhs, rhs in
            (lhs.lastModified ?? .distantPast) > (rhs.lastModified ?? .distantPast)
        }.first
    }

    func firstMatch(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard
            let match = regex.firstMatch(in: text, range: fullRange),
            match.numberOfRanges >= 2,
            let swiftRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        return String(text[swiftRange])
    }

    func parseLoggedTimers(from message: String) -> [LoggedTimerSummary] {
        guard let regex = try? NSRegularExpression(pattern: "<MT(?:Mutable)?Timer:[^>]+>") else {
            return []
        }

        let fullRange = NSRange(message.startIndex..<message.endIndex, in: message)
        return regex.matches(in: message, range: fullRange).compactMap { match in
            guard let swiftRange = Range(match.range, in: message) else {
                return nil
            }

            let timerDescription = String(message[swiftRange])
            guard let identifier = firstMatch(
                pattern: "TimerID:\\s*([A-Fa-f0-9\\-]+)",
                in: timerDescription
            ) else {
                return nil
            }

            let stateToken = firstMatch(pattern: "state:([A-Za-z]+)", in: timerDescription)?.lowercased()
            let state = Self.preferencesState(from: stateToken)
            let title = firstMatch(pattern: "Title:\\s*([^,]+)", in: timerDescription)
            let duration = firstMatch(
                pattern: "duration:([0-9]+(?:\\.[0-9]+)?)",
                in: timerDescription
            ).flatMap(Double.init)

            return LoggedTimerSummary(
                identifier: identifier.uppercased(),
                state: state,
                title: title,
                duration: duration
            )
        }
    }

    static func preferencesState(from token: String?) -> PreferencesTimer.State? {
        switch token {
        case "running":
            return .running
        case "paused":
            return .paused
        case "stopped":
            return .stopped
        case "fired":
            return .fired
        default:
            return nil
        }
    }

    func startAccessibilityFallbackIfPossible() {
        #if canImport(ApplicationServices)
        guard AXIsProcessTrusted() else {
            logger.debug("Skipping Accessibility fallback because AX permission is missing")
            postAccessibilityWarningIfNeeded()
            return
        }

        guard accessibilityTicker == nil else { return }

        let ticker = DispatchSource.makeTimerSource(queue: queue)
        ticker.schedule(deadline: .now(), repeating: fallbackPollInterval)
        ticker.setEventHandler { [weak self] in
            self?.pollAccessibilityTimer()
        }
        ticker.resume()
        accessibilityTicker = ticker
        #endif
    }

    func stopAccessibilityFallback() {
        accessibilityTicker?.setEventHandler {}
        accessibilityTicker?.cancel()
        accessibilityTicker = nil

        #if canImport(ApplicationServices)
        menuBarTimerItem = nil
        #endif
    }

    #if canImport(ApplicationServices)
    func pollAccessibilityTimer() {
        if logProcess != nil, trackedTimerID != nil, currentRemaining != nil {
            return
        }

        if menuBarTimerItem == nil {
            menuBarTimerItem = findMenuBarTimerItem()
        }

        guard let menuBarTimerItem else {
            if logProcess == nil, preferencesTimer?.state.isActive != true {
                clearTrackedTimer()
            }
            return
        }

        guard let sample = extractMenuBarSample(from: menuBarTimerItem) else {
            self.menuBarTimerItem = nil
            if logProcess == nil, preferencesTimer?.state.isActive != true {
                clearTrackedTimer()
            }
            return
        }

        if trackedTimerID == nil, let preferencesTimer, preferencesTimer.state.isActive {
            beginTracking(timerID: preferencesTimer.identifier)
        }

        recordRemaining(sample.remaining, paused: sample.isPaused)
    }

    func findMenuBarTimerItem() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        guard let menuBar: AXUIElement = axAttribute(kAXMenuBarAttribute, from: systemWide) else {
            return nil
        }

        let children: [AXUIElement] = axAttribute(kAXChildrenAttribute, from: menuBar) ?? []
        return children.first(where: looksLikeTimerMenuBarItem)
    }

    func looksLikeTimerMenuBarItem(_ element: AXUIElement) -> Bool {
        let candidates = [
            accessibilityString(for: kAXIdentifierAttribute, in: element),
            accessibilityString(for: kAXTitleAttribute, in: element),
            accessibilityString(for: kAXValueAttribute, in: element)
        ].compactMap { $0 }

        if candidates.contains(where: { $0.localizedCaseInsensitiveContains("timer") }) {
            return true
        }

        if candidates.contains(where: { parseCountdownToken(from: $0) != nil }) {
            return true
        }

        let children: [AXUIElement] = axAttribute(kAXChildrenAttribute, from: element) ?? []
        for child in children {
            let childCandidates = [
                accessibilityString(for: kAXTitleAttribute, in: child),
                accessibilityString(for: kAXValueAttribute, in: child)
            ].compactMap { $0 }

            if childCandidates.contains(where: { parseCountdownToken(from: $0) != nil }) {
                return true
            }
        }

        return false
    }

    func extractMenuBarSample(from element: AXUIElement) -> MenuBarTimerSample? {
        let candidates = [
            accessibilityString(for: kAXValueAttribute, in: element),
            accessibilityString(for: kAXTitleAttribute, in: element)
        ].compactMap { $0 }

        for candidate in candidates {
            if let sample = menuBarSample(from: candidate) {
                return sample
            }
        }

        let children: [AXUIElement] = axAttribute(kAXChildrenAttribute, from: element) ?? []
        for child in children {
            let childCandidates = [
                accessibilityString(for: kAXValueAttribute, in: child),
                accessibilityString(for: kAXTitleAttribute, in: child)
            ].compactMap { $0 }

            for candidate in childCandidates {
                if let sample = menuBarSample(from: candidate) {
                    return sample
                }
            }
        }

        return nil
    }

    func menuBarSample(from rawValue: String) -> MenuBarTimerSample? {
        guard let remaining = parseCountdownToken(from: rawValue) else {
            return nil
        }

        let normalized = rawValue.lowercased()
        let isPaused = normalized.contains("pause") ||
            normalized.contains("stopped") ||
            normalized.contains("paused")

        return MenuBarTimerSample(remaining: remaining, isPaused: isPaused)
    }

    func parseCountdownToken(from text: String) -> TimeInterval? {
        let numericPattern = "[0-9]+(?::[0-9]{2}){0,2}"
        if let range = text.range(of: numericPattern, options: .regularExpression) {
            let components = text[range].split(separator: ":").compactMap { Double($0) }
            switch components.count {
            case 1:
                return components[0]
            case 2:
                return (components[0] * 60) + components[1]
            case 3:
                return (components[0] * 3600) + (components[1] * 60) + components[2]
            default:
                break
            }
        }

        guard let regex = try? NSRegularExpression(pattern: "([0-9]+)([hms])") else {
            return nil
        }

        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: fullRange)
        guard !matches.isEmpty else { return nil }

        var total: TimeInterval = 0
        for match in matches {
            guard match.numberOfRanges == 3,
                  let valueRange = Range(match.range(at: 1), in: text),
                  let unitRange = Range(match.range(at: 2), in: text),
                  let value = Double(text[valueRange]) else {
                continue
            }

            switch text[unitRange] {
            case "h":
                total += value * 3600
            case "m":
                total += value * 60
            case "s":
                total += value
            default:
                break
            }
        }

        return total > 0 ? total : nil
    }

    func axAttribute<T>(_ attribute: String, from element: AXUIElement) -> T? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else {
            return nil
        }
        return value as? T
    }

    func accessibilityString(for attribute: String, in element: AXUIElement) -> String? {
        guard let value: String = axAttribute(attribute, from: element) else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    #endif

    func postAccessibilityWarningIfNeeded() {
        guard !didWarnAboutAccessibility else { return }
        didWarnAboutAccessibility = true
        logger.error("Accessibility permission is required to mirror Clock timers")

        DispatchQueue.main.async {
            debugPrint(
                "[ClockTimerMonitor] Accessibility permission is required to mirror Clock timers. " +
                "Grant access in System Settings -> Privacy & Security -> Accessibility."
            )
        }
    }
}
