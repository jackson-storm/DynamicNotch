import Foundation
internal import AppKit
#if canImport(ApplicationServices)
import ApplicationServices
#endif
import OSLog

nonisolated enum ClockTimerState: Int {
    case unknown = 0
    case stopped = 1
    case running = 2
    case paused = 3
    case fired = 4

    var isActive: Bool {
        self == .running || self == .paused
    }
}

nonisolated enum ClockTimerLogParser {
    struct Entry: Equatable {
        let identifier: String
        let state: ClockTimerState?
        let title: String?
        let duration: TimeInterval?
    }

    static func updatedTimers(in message: String) -> [Entry] {
        guard message.contains("didUpdateTimers"),
              let range = message.range(of: "toTimers:") else {
            return []
        }

        // The fromTimers section is the state before the change, so only the text after toTimers: counts.
        return timers(in: String(message[range.upperBound...]))
    }

    static func timers(in message: String) -> [Entry] {
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
            let title = firstMatch(pattern: "Title:\\s*([^,]+)", in: timerDescription)
            let duration = firstMatch(
                pattern: "duration:([0-9]+(?:\\.[0-9]+)?)",
                in: timerDescription
            ).flatMap(Double.init)

            return Entry(
                identifier: identifier.uppercased(),
                state: state(from: stateToken),
                title: title,
                duration: duration
            )
        }
    }

    static func state(from token: String?) -> ClockTimerState? {
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

    static func firstMatch(pattern: String, in text: String) -> String? {
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

    /// Parses an ndjson `timestamp` such as `2026-11-02 11:20:38.639916-0800`.
    static func logTimestamp(_ text: String) -> Date? {
        guard let dot = text.firstIndex(of: ".") else {
            return logTimestampFormatter.date(from: text)
        }

        let afterDot = text[text.index(after: dot)...]
        let digits = afterDot.prefix(while: \.isNumber)
        let offset = afterDot.dropFirst(digits.count)

        guard
            !digits.isEmpty,
            offset.count == 5,
            offset.first == "+" || offset.first == "-",
            offset.dropFirst().allSatisfy(\.isNumber),
            let base = logTimestampFormatter.date(from: String(text[..<dot]) + offset),
            let fraction = Double("0." + digits)
        else {
            return nil
        }

        return base.addingTimeInterval(fraction)
    }

    // DateFormatter keeps only milliseconds, so the fraction is added separately.
    private static let logTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        return formatter
    }()
}

nonisolated enum ClockTimerPreferencesParser {
    static func state(forTimer timer: [String: Any]) -> ClockTimerState {
        let rawState = timer["MTTimerState"] as? Int ?? 0

        // Running and paused timers both persist raw state 2. Only a running timer stores its fire
        // time as an MTTimerDate.
        if rawState == ClockTimerState.running.rawValue,
           timer["MTTimerFireTimerClass"] as? String != "MTTimerDate" {
            return .paused
        }

        return ClockTimerState(rawValue: rawState) ?? .unknown
    }

    /// `defaults` renders the date as a string, so both forms are accepted.
    static func fireDate(forTimer timer: [String: Any]) -> Date? {
        let fireTime = (timer["MTTimerFireTime"] as? [String: Any])?["$MTTimerDate"] as? [String: Any]
        switch fireTime?["MTTimerTimeDate"] {
        case let date as Date:
            return date
        case let text as String:
            return fireDateFormatter.date(from: text)
        default:
            return nil
        }
    }

    private static let fireDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter
    }()
}

/// All state stays in `queue`.
nonisolated final class ReplaceableFileWatcher: @unchecked Sendable {
    private let path: String
    private let queue: DispatchQueue
    private let reopenAttempts: Int
    private let reopenDelay: TimeInterval
    private let onChange: () -> Void

    private var descriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?
    private var isCancelled = false

    init(
        path: String,
        queue: DispatchQueue,
        reopenAttempts: Int = 5,
        reopenDelay: TimeInterval = 0.05,
        onChange: @escaping () -> Void
    ) {
        self.path = path
        self.queue = queue
        self.reopenAttempts = reopenAttempts
        self.reopenDelay = reopenDelay
        self.onChange = onChange
    }

    @discardableResult
    func start() -> Bool {
        isCancelled = false
        return arm()
    }

    func cancel() {
        isCancelled = true
        disarm()
    }

    private func arm() -> Bool {
        let descriptor = open(path, O_EVTONLY)
        guard descriptor != -1 else { return false }

        self.descriptor = descriptor

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .rename, .delete, .attrib],
            queue: queue
        )

        source.setEventHandler { [weak self, weak source] in
            guard let self, let source else { return }
            self.handle(events: source.data)
        }

        source.resume()
        self.source = source
        return true
    }

    private func disarm() {
        source?.setEventHandler {}
        source?.cancel()
        source = nil

        if descriptor != -1 {
            close(descriptor)
            descriptor = -1
        }
    }

    private func handle(events: DispatchSource.FileSystemEvent) {
        guard !isCancelled else { return }

        guard events.contains(.delete) || events.contains(.rename) else {
            onChange()
            return
        }

        // An atomic replace unlinks the watched inode, so the descriptor never sees another event.
        disarm()
        rearm(attempt: 0)
    }

    private func rearm(attempt: Int) {
        guard !isCancelled else { return }

        if arm() {
            onChange()
            return
        }

        guard attempt < reopenAttempts else { return }

        queue.asyncAfter(deadline: .now() + reopenDelay) { [weak self] in
            self?.rearm(attempt: attempt + 1)
        }
    }
}

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
    /// Use the pause state from the last logged transition. cfprefsd rewrites the preferences after
    /// the log, so this pause state takes precedence once set.
    private var loggedPausedState: Bool?
    /// The logged pause was applied at this remaining time. A resume requires a drop greater than
    /// one sample's rounding because Clock logs one more remainingTime sample after a pause.
    private var pausedBaselineRemaining: TimeInterval?
    private var lastPublishedSnapshot: ClockTimerSnapshot?
    private var lastSampleTime: Date?
    private var lastSampleRemaining: TimeInterval?
    private var recentSampleIntervals: [TimeInterval] = []
    private var redrawPeriod: TimeInterval?
    /// Implied delays that agree with the current phase. Empty while the phase is unknown.
    private var phaseDelays: [TimeInterval] = []
    /// One implied delay that disagreed with the current phase, kept to confirm a phase change.
    private var pendingPhaseDelay: TimeInterval?
    private var displayDelay: TimeInterval = 0

    private var logProcess: Process?
    private var logPipe: Pipe?
    private var logBuffer = Data()
    private var logRestartWorkItem: DispatchWorkItem?
    private var completionClearWorkItem: DispatchWorkItem?

    private var preferencesWatcher: ReplaceableFileWatcher?
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

    /// Handles one mobiletimerd or Clock log message on the monitor's queue.
    func ingestLogMessage(_ message: String) {
        queue.async { [weak self] in
            self?.processLogMessage(message)
        }
    }

    /// Handles one `log stream --style ndjson` line on the monitor's queue.
    func ingestLogLine(_ line: String) {
        queue.async { [weak self] in
            self?.processLogLine(Data(line.utf8))
        }
    }

    /// This rereads the preferences timer on the monitor's queue, as the preferences watcher does.
    func ingestPreferencesChange() {
        queue.async { [weak self] in
            self?.reloadPreferencesTimer()
        }
    }
}

private extension ClockTimerMonitor {
    struct PreferencesTimer: Equatable {
        typealias State = ClockTimerState

        let identifier: String
        let title: String
        let duration: TimeInterval
        let state: State
        let lastModified: Date?
        /// Only a running timer stores the end of the visible countdown.
        let fireDate: Date?
    }

    typealias LoggedTimerSummary = ClockTimerLogParser.Entry

    #if canImport(ApplicationServices)
    struct MenuBarTimerSample {
        let remaining: TimeInterval
        let isPaused: Bool
    }
    #endif

    var isMonitoring: Bool {
        logProcess != nil || preferencesWatcher != nil || accessibilityTicker != nil
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

        preferencesWatcher?.cancel()
        preferencesWatcher = nil

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
        resetRedrawPhase()

        if clearSnapshot {
            publish(snapshot: nil)
        }
    }

    func startPreferencesMonitor() {
        guard preferencesWatcher == nil else { return }

        let watcher = ReplaceableFileWatcher(path: metadataFilePath, queue: queue) { [weak self] in
            self?.reloadPreferencesTimer()
        }

        guard watcher.start() else {
            logger.debug("Timer preferences file is not available at \(self.metadataFilePath, privacy: .public)")
            return
        }

        preferencesWatcher = watcher
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

        let sampleTime = (payload["timestamp"] as? String).flatMap(ClockTimerLogParser.logTimestamp)
        processLogMessage(message, sampleTime: sampleTime)
    }

    func processLogMessage(_ message: String, sampleTime: Date? = nil) {
        if message.contains("didUpdateTimers") {
            applyUpdatedTimersMessage(message)
        }

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
            applyRemainingTimeMessage(message, sampleTime: sampleTime)
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
        applyLoggedState(state)
    }

    func applyUpdatedTimersMessage(_ message: String) {
        let timers = ClockTimerLogParser.updatedTimers(in: message)
        guard !timers.isEmpty else { return }

        let selectedTimer: LoggedTimerSummary?

        if let trackedID = trackedTimerID?.uppercased() {
            selectedTimer = timers.first(where: { $0.identifier == trackedID })
        } else {
            selectedTimer = timers.first(where: { $0.state?.isActive == true })
            if let selectedTimer {
                beginTracking(timerID: selectedTimer.identifier)
            }
        }

        guard let state = selectedTimer?.state else { return }

        if state == .paused, let liveRemaining = liveRunningRemaining() {
            currentRemaining = liveRemaining
        }

        applyLoggedState(state)
    }

    /// The remaining time for the running snapshot advances on screen between log lines, while
    /// `currentRemaining` keeps the value from the last line that included one.
    func liveRunningRemaining() -> TimeInterval? {
        guard
            let lastPublishedSnapshot,
            !lastPublishedSnapshot.isPaused,
            lastPublishedSnapshot.identifier == trackedTimerID
        else {
            return nil
        }

        return lastPublishedSnapshot.remainingTime(at: dateProvider())
    }

    func applyLoggedState(_ state: PreferencesTimer.State) {
        switch state {
        case .paused:
            resetRedrawPhase()
            loggedPausedState = true
            pausedBaselineRemaining = nil
            if let currentRemaining {
                applyLogDrivenUpdate(remaining: currentRemaining, paused: true)
            } else {
                currentPausedState = true
            }
            pausedBaselineRemaining = currentRemaining

        case .running:
            if currentPausedState {
                resetRedrawPhase()
            }
            loggedPausedState = false
            pausedBaselineRemaining = nil
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
            // After the transition sets the paused state, the pause also logs a null next timer.
            if currentPausedState {
                return
            }

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

        // The scheduler fires its alert 10 s before the countdown ends, so it only seeds an unknown
        // remaining time.
        guard currentRemaining == nil else { return }

        applyLogDrivenUpdate(remaining: minutes * 60, paused: currentPausedState)
    }

    func applyRemainingTimeMessage(_ message: String, sampleTime: Date?) {
        guard let remainingToken = firstMatch(pattern: "remainingTime:\\s*([-0-9.]+)", in: message),
              let remaining = Double(remainingToken) else {
            return
        }

        let isRunning = !currentPausedState
        if !isRunning || trackedTimerID == nil {
            resetRedrawPhase()
        } else if let sampleTime {
            learnRedrawPhase(sampleTime: sampleTime, remaining: remaining)
        }

        let sampleAge = sampleTime.map { max(0, dateProvider().timeIntervalSince($0)) } ?? 0
        let remainingNow = isRunning ? remaining - sampleAge : remaining
        applyLogDrivenUpdate(remaining: remainingNow, paused: currentPausedState, isExact: true)

        if currentPausedState {
            resetRedrawPhase()
        }
    }

    func learnRedrawPhase(sampleTime: Date, remaining: TimeInterval) {
        let previousRemaining = lastSampleRemaining
        // A gap longer than 1.5 s says nothing about the grid period, and the next redraws confirm
        // or replace the phase.
        if let lastSampleTime {
            let interval = sampleTime.timeIntervalSince(lastSampleTime)
            if interval <= 1.5 {
                recentSampleIntervals = Array((recentSampleIntervals + [interval]).suffix(4))
            }
        }
        lastSampleTime = sampleTime
        lastSampleRemaining = remaining

        if phaseDelays.isEmpty {
            redrawPeriod = Self.redrawGridPeriod(intervals: recentSampleIntervals)
        } else if let gridPeriod = Self.redrawGridPeriod(intervals: recentSampleIntervals),
                  let redrawPeriod,
                  abs(gridPeriod - redrawPeriod) > 0.000_001 {
            phaseDelays = []
            pendingPhaseDelay = nil
            self.redrawPeriod = gridPeriod
        }
        guard let period = redrawPeriod else { return }

        let delay = Self.impliedRedrawDelay(remaining: remaining, period: period)
        if phaseDelays.isEmpty {
            guard let previousRemaining else { return }
            let previousDelay = Self.impliedRedrawDelay(remaining: previousRemaining, period: period)
            // Two consecutive redraws within 4 ms of each other fix the phase.
            guard Self.circularDistance(delay, previousDelay, period: period) <= 0.004 else { return }
            phaseDelays = [previousDelay, delay]
        } else {
            let currentDelay = Self.circularMedian(phaseDelays, period: period)
            // 12 ms covers the grid's measured jitter, so one late redraw stays in the current phase.
            if Self.circularDistance(delay, currentDelay, period: period) <= 0.012 {
                phaseDelays = Array((phaseDelays + [delay]).suffix(5))
                pendingPhaseDelay = nil
            } else if let pendingPhaseDelay,
                      Self.circularDistance(delay, pendingPhaseDelay, period: period) <= 0.004 {
                phaseDelays = [pendingPhaseDelay, delay]
                self.pendingPhaseDelay = nil
            } else {
                pendingPhaseDelay = delay
            }
        }

        // 4 ms is a quarter of a 60 Hz frame, so jitter does not republish four times a second.
        let learnedDelay = Self.circularMedian(phaseDelays, period: period)
        if Self.circularDistance(learnedDelay, displayDelay, period: period) > 0.004 {
            displayDelay = learnedDelay
        }
    }

    func resetRedrawPhase() {
        lastSampleTime = nil
        lastSampleRemaining = nil
        recentSampleIntervals = []
        redrawPeriod = nil
        phaseDelays = []
        pendingPhaseDelay = nil
        displayDelay = 0
    }

    func handleTimerStoppedMessage() {
        guard trackedTimerID != nil else { return }
        guard completionClearWorkItem == nil else { return }
        clearTrackedTimer()
    }

    func applyLogDrivenUpdate(remaining: TimeInterval, paused: Bool, isExact: Bool = false) {
        guard trackedTimerID != nil || preferencesTimer?.state.isActive == true else { return }
        recordRemaining(remaining, paused: paused, isExact: isExact)
    }

    func recordRemaining(_ remaining: TimeInterval, paused: Bool, isExact: Bool = false) {
        let resolvedRemaining = max(0, remaining)
        var resolvedPaused = paused

        if loggedPausedState == true, paused {
            if let baseline = pausedBaselineRemaining {
                // The log did not record the resume. Treat the resume as recorded so the paused
                // preferences cached since the pause cannot pause the timer again.
                if (baseline - resolvedRemaining) > 1.75 {
                    resolvedPaused = false
                    loggedPausedState = false
                    pausedBaselineRemaining = nil
                }
            } else {
                pausedBaselineRemaining = resolvedRemaining
            }
        } else if loggedPausedState == nil {
            if let previousRemaining = currentRemaining,
               paused,
               (previousRemaining - resolvedRemaining) > 0.75 {
                resolvedPaused = false
            }

            if preferencesTimer?.state == .paused {
                resolvedPaused = true
            }
        }

        currentRemaining = resolvedRemaining
        currentPausedState = resolvedPaused

        if resolvedRemaining <= 0 {
            publishCurrentSnapshot(isExact: isExact)
            scheduleCompletionClear()
            return
        }

        cancelCompletionClear()
        publishCurrentSnapshot(isExact: isExact)
    }

    func publishCurrentSnapshot(isExact: Bool = false) {
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
            now: now,
            displayDelay: displayDelay
        )

        publish(snapshot: stabilizedSnapshot(for: candidate, now: now, isExact: isExact))
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
        now: Date,
        displayDelay: TimeInterval = 0
    ) -> ClockTimerSnapshot {
        let resolvedRemaining = max(0, remaining)
        let endDate = now.addingTimeInterval(resolvedRemaining)

        return snapshot(
            identifier: identifier,
            title: title,
            duration: duration,
            endDate: endDate,
            isPaused: isPaused,
            pausedRemaining: isPaused ? resolvedRemaining : nil,
            displayDelay: isPaused ? 0 : displayDelay
        )
    }

    func snapshot(
        identifier: String,
        title: String,
        duration: TimeInterval,
        endDate: Date,
        isPaused: Bool,
        pausedRemaining: TimeInterval?,
        displayDelay: TimeInterval = 0
    ) -> ClockTimerSnapshot {
        let roundedDuration = max(1, duration.rounded())
        let resolvedPausedRemaining = pausedRemaining.map { max(0, $0) }
        let fingerprint: String

        if isPaused {
            fingerprint = [
                identifier,
                title,
                "paused",
                String(Int((resolvedPausedRemaining ?? 0).rounded())),
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
            pausedRemaining: resolvedPausedRemaining,
            fingerprint: fingerprint,
            displayDelay: isPaused ? 0 : displayDelay
        )
    }

    func stabilizedSnapshot(for snapshot: ClockTimerSnapshot, now: Date, isExact: Bool = false) -> ClockTimerSnapshot {
        guard let lastPublishedSnapshot else {
            return snapshot
        }

        guard
            lastPublishedSnapshot.identifier == snapshot.identifier,
            lastPublishedSnapshot.title == snapshot.title
        else {
            return snapshot
        }

        // Exact sources agree within microseconds, so they may correct a published snapshot by more
        // than 0.002 s.
        let pausedTolerance: TimeInterval = isExact ? 0.002 : 1
        let runningTolerance: TimeInterval = isExact ? 0.002 : 2

        if snapshot.isPaused {
            let previousRemaining = lastPublishedSnapshot.pausedRemaining ?? lastPublishedSnapshot.remainingTime(at: now)
            let currentRemaining = snapshot.pausedRemaining ?? snapshot.remainingTime(at: now)

            guard lastPublishedSnapshot.isPaused, abs(previousRemaining - currentRemaining) <= pausedTolerance else {
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
            abs(lastPublishedSnapshot.endDate.timeIntervalSince(snapshot.endDate)) <= runningTolerance
        else {
            return snapshot
        }

        return self.snapshot(
            identifier: snapshot.identifier,
            title: snapshot.title,
            duration: max(lastPublishedSnapshot.duration, snapshot.duration, snapshot.remainingTime(at: now)),
            endDate: lastPublishedSnapshot.endDate,
            isPaused: false,
            pausedRemaining: nil,
            displayDelay: snapshot.displayDelay
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
        loggedPausedState = nil
        pausedBaselineRemaining = nil
        resetRedrawPhase()
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
        loggedPausedState = nil
        pausedBaselineRemaining = nil
        resetRedrawPhase()
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
            let wasPaused = currentPausedState
            if loggedPausedState == nil {
                currentPausedState = false
            }
            let pauseChanged = wasPaused != currentPausedState
            if applyPreferencesFireDate(of: preferencesTimer) {
                break
            }
            if currentRemaining != nil, pauseChanged || previousTimer?.duration != preferencesTimer.duration {
                publishCurrentSnapshot()
            }

        case .paused:
            guard loggedPausedState == nil else { break }
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

    /// Returns true when the fire date replaces the remaining time.
    func applyPreferencesFireDate(of preferencesTimer: PreferencesTimer) -> Bool {
        guard
            loggedPausedState != true,
            let fireDate = preferencesTimer.fireDate,
            preferencesTimer.identifier.uppercased() == trackedTimerID?.uppercased()
        else {
            return false
        }

        let exact = fireDate.timeIntervalSince(dateProvider())
        guard exact > 0 else { return false }

        if currentRemaining != nil,
           let liveRemaining = liveRunningRemaining(),
           abs(liveRemaining - exact) <= 0.002 {
            return false
        }

        recordRemaining(exact, paused: false, isExact: true)
        return true
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

            return PreferencesTimer(
                identifier: identifier,
                title: title,
                duration: duration,
                state: ClockTimerPreferencesParser.state(forTimer: timer),
                lastModified: timer["MTTimerLastModifiedDate"] as? Date,
                fireDate: ClockTimerPreferencesParser.fireDate(forTimer: timer)
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
        ClockTimerLogParser.firstMatch(pattern: pattern, in: text)
    }

    func parseLoggedTimers(from message: String) -> [LoggedTimerSummary] {
        ClockTimerLogParser.timers(in: message)
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

extension ClockTimerMonitor {
    /// Clock redraws on a grid whose period divides one second, so each digit flips at the same
    /// delay after its half-second crossing. The last three intervals must all be within 5 ms of
    /// the same 1/n s because one startup redraw can fall near a wrong frame length.
    static func redrawGridPeriod(intervals: [TimeInterval]) -> TimeInterval? {
        guard intervals.count >= 3 else { return nil }
        let recent = Array(intervals.suffix(3))
        let median = recent.sorted()[1]
        guard median > 0 else { return nil }

        let frames = (1 / median).rounded()
        guard frames >= 1, frames <= 120 else { return nil }
        let period = 1 / frames
        return recent.allSatisfy { abs($0 - period) <= 0.005 } ? period : nil
    }

    static func impliedRedrawDelay(remaining: TimeInterval, period: TimeInterval) -> TimeInterval {
        normalizedDelay(0.5 - remaining, period: period)
    }

    static func normalizedDelay(_ delay: TimeInterval, period: TimeInterval) -> TimeInterval {
        let wrapped = delay.truncatingRemainder(dividingBy: period)
        return wrapped < 0 ? wrapped + period : wrapped
    }

    static func circularDistance(_ lhs: TimeInterval, _ rhs: TimeInterval, period: TimeInterval) -> TimeInterval {
        let difference = abs(lhs - rhs).truncatingRemainder(dividingBy: period)
        return min(difference, period - difference)
    }

    static func circularMedian(_ delays: [TimeInterval], period: TimeInterval) -> TimeInterval {
        guard let reference = delays.first else { return 0 }
        let offsets = delays.map { delay -> TimeInterval in
            var offset = (delay - reference).truncatingRemainder(dividingBy: period)
            if offset >= period / 2 { offset -= period }
            if offset < -period / 2 { offset += period }
            return offset
        }.sorted()

        let middle = offsets.count / 2
        let medianOffset = offsets.count.isMultiple(of: 2)
            ? (offsets[middle - 1] + offsets[middle]) / 2
            : offsets[middle]
        return normalizedDelay(reference + medianOffset, period: period)
    }
}
