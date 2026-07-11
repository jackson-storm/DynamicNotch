import Foundation
import SwiftUI
import Combine
internal import AppKit

final class DoNotDisturbManager: ObservableObject {
    static let shared = DoNotDisturbManager()

    @Published private(set) var isMonitoring = false
    @Published var isDoNotDisturbActive = false
    @Published var currentFocusModeName: String = ""
    @Published var currentFocusModeIdentifier: String = ""

    private let notificationCenter = DistributedNotificationCenter.default()
    private let metadataExtractionQueue = DispatchQueue(
        label: "com.dynamicisland.focus.metadata",
        qos: .userInitiated
    )
    let focusLogStream = FocusLogStream()

    private var metadataClearTask: Task<Void, Never>?

    // Authoritative Focus state from ~/Library/DoNotDisturb/DB/Assertions.json
    // (requires Full Disk Access). Watched via a directory vnode source plus a
    // slow poll fallback, since notifications/log are unreliable on macOS 26.
    private var assertionsSource: DispatchSourceFileSystemObject?
    private var assertionsPollTimer: Timer?

    private init() {
        focusLogStream.onMetadataUpdate = { [weak self] identifier, name in
            self?.handleLogMetadataUpdate(identifier: identifier, name: name)
        }
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }

        notificationCenter.addObserver(
            self,
            selector: #selector(handleFocusEnabled(_:)),
            name: .focusModeEnabled,
            object: nil,
            suspensionBehavior: .deliverImmediately
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleFocusDisabled(_:)),
            name: .focusModeDisabled,
            object: nil,
            suspensionBehavior: .deliverImmediately
        )

        focusLogStream.start()
        checkInitialFocusStateViaLog()
        startAssertionMonitoring()
        isMonitoring = true
    }

    func stopMonitoring() {
        guard isMonitoring else { return }

        notificationCenter.removeObserver(self, name: .focusModeEnabled, object: nil)
        notificationCenter.removeObserver(self, name: .focusModeDisabled, object: nil)

        focusLogStream.stop()
        stopAssertionMonitoring()
        metadataClearTask?.cancel()
        metadataClearTask = nil
        isMonitoring = false

        DispatchQueue.main.async {
            self.isDoNotDisturbActive = false
            self.currentFocusModeIdentifier = ""
            self.currentFocusModeName = ""
        }
    }

    @objc private func handleFocusEnabled(_ notification: Notification) {
        apply(notification: notification, isActive: true)
    }

    @objc private func handleFocusDisabled(_ notification: Notification) {
        apply(notification: notification, isActive: false)
    }

    private func apply(notification: Notification, isActive: Bool) {
        metadataExtractionQueue.async { [weak self] in
            guard let self else { return }

            let metadata = self.extractMetadata(from: notification)
            self.publishMetadata(
                identifier: metadata.identifier,
                name: metadata.name,
                isActive: isActive,
                source: notification.name.rawValue
            )
        }
    }

    private func publishMetadata(
        identifier: String?,
        name: String?,
        isActive: Bool?,
        source: String
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            let trimmedIdentifier = identifier?.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)

            let isGenericFocusIdentifier = (trimmedIdentifier?.lowercased() == "com.apple.focus")
            let usableIdentifier = (trimmedIdentifier?.isEmpty == false && !isGenericFocusIdentifier) ? trimmedIdentifier : nil
            let usableName = (trimmedName?.isEmpty == false) ? trimmedName : nil

            let previousIdentifier = self.currentFocusModeIdentifier
            let previousName = self.currentFocusModeName
            let previousActive = self.isDoNotDisturbActive

            // When neither identifier nor name is available, only update the active
            // state without overwriting existing mode metadata. We deliberately avoid
            // eagerly assigning the generic Do Not Disturb identity here: the specific
            // mode metadata (e.g. Work) usually arrives a moment later via the log
            // stream, and stamping DND first makes the notch briefly flash the crescent
            // moon icon before the real mode is resolved. The consumer (FocusService)
            // holds a short grace period so genuine DND still falls back correctly.
            if usableIdentifier == nil && usableName == nil {
                if let isActive = isActive, isActive != previousActive {
                    withAnimation(.smooth(duration: 0.25)) {
                        self.isDoNotDisturbActive = isActive
                    }
                    debugPrint("[DoNotDisturbManager] Focus active-only update -> source: \(source) | isActive: \(isActive)")
                }
                return
            }

            let resolvedMode = FocusModeType.resolve(identifier: usableIdentifier, name: usableName)
            let finalIdentifier: String = usableIdentifier ?? resolvedMode.rawValue

            // Compute display name
            let finalName: String
            if resolvedMode == .custom, !FullDiskAccessAuthorization.hasPermission() {
                if let tn = trimmedName, !tn.isEmpty, !tn.contains(".") {
                    finalName = tn
                } else {
                    finalName = "Focus"
                }
            } else if resolvedMode == .custom, FullDiskAccessAuthorization.hasPermission() {
                let lookedUp = FocusMetadataReader.shared.getDisplayName(for: trimmedName ?? "", identifier: finalIdentifier)
                if !lookedUp.isEmpty {
                    finalName = lookedUp
                } else if let tn = trimmedName, !tn.isEmpty, !tn.contains(".") {
                    finalName = tn
                } else {
                    finalName = "Focus"
                }
            } else if let name = trimmedName, !name.isEmpty {
                let lower = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                switch lower {
                case "work", "работа":
                    finalName = "Work"
                case "personal", "personal-time", "личное":
                    finalName = "Personal"
                case "reduce-interruptions", "reduce interruptions":
                    finalName = "Reduce Interruptions"
                case "sleep", "sleep-mode", "сон":
                    finalName = "Sleep"
                case "driving", "за рулем":
                    finalName = "Driving"
                case "default", "dnd", "do-not-disturb", "do not disturb", "donotdisturb", "не беспокоить":
                    finalName = "Do Not Disturb"
                default:
                    finalName = name
                }
            } else if !resolvedMode.displayName.isEmpty {
                finalName = resolvedMode.displayName
            } else {
                finalName = "Focus"
            }

            let identifierChanged = finalIdentifier != previousIdentifier
            let nameChanged = finalName != previousName
            let shouldToggleActive = isActive.map { $0 != previousActive } ?? false

            if identifierChanged {
                self.currentFocusModeIdentifier = finalIdentifier
            }

            if nameChanged {
                self.currentFocusModeName = finalName.localizedCaseInsensitiveContains(
                    "Reduce Interruptions"
                ) ? "Reduce Interr." : finalName
            }

            if identifierChanged || nameChanged || shouldToggleActive {
                debugPrint(
                    "[DoNotDisturbManager] Focus update -> source: \(source) | identifier: \(trimmedIdentifier ?? "<nil>") | name: \(trimmedName ?? "<nil>") | resolved: \(resolvedMode.rawValue)"
                )
            }

            guard let isActive = isActive, shouldToggleActive else { return }

            withAnimation(.smooth(duration: 0.25)) {
                self.isDoNotDisturbActive = isActive
            }

            if isActive == false {
                self.currentFocusModeIdentifier = previousIdentifier
                self.currentFocusModeName = previousName
                self.scheduleMetadataClear()
            } else {
                self.metadataClearTask?.cancel()
                self.metadataClearTask = nil
            }
        }
    }

    // MARK: - Assertions.json (authoritative Focus state)

    private func startAssertionMonitoring() {
        metadataExtractionQueue.async { [weak self] in
            self?.refreshFromAssertions()
        }

        let directory = FocusAssertionsReader.shared.fileURL.deletingLastPathComponent()
        let descriptor = open(directory.path, O_EVTONLY)
        if descriptor >= 0 {
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: descriptor,
                eventMask: [.write, .rename, .delete, .attrib],
                queue: metadataExtractionQueue
            )
            source.setEventHandler { [weak self] in
                self?.refreshFromAssertions()
            }
            source.setCancelHandler {
                close(descriptor)
            }
            assertionsSource = source
            source.resume()
        }

        // Fallback poll in case the vnode source misses an atomic replace or the
        // directory couldn't be opened for events.
        let timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.metadataExtractionQueue.async { [weak self] in
                self?.refreshFromAssertions()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        assertionsPollTimer = timer
    }

    private func stopAssertionMonitoring() {
        assertionsSource?.cancel()
        assertionsSource = nil
        assertionsPollTimer?.invalidate()
        assertionsPollTimer = nil
    }

    private func refreshFromAssertions() {
        switch FocusAssertionsReader.shared.readState() {
        case .unreadable:
            // No Full Disk Access — leave the legacy notification/log paths in charge.
            return
        case .off:
            publishMetadata(identifier: nil, name: nil, isActive: false, source: "assertions-off")
        case .on(let identifier):
            publishMetadata(identifier: identifier, name: nil, isActive: true, source: "assertions-on")
        }
    }

    private func scheduleMetadataClear() {
        metadataClearTask?.cancel()
        metadataClearTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard let self, !self.isDoNotDisturbActive else { return }
            self.currentFocusModeIdentifier = ""
            self.currentFocusModeName = ""
        }
    }

    private func handleLogMetadataUpdate(identifier: String?, name: String?) {
        metadataExtractionQueue.async { [weak self] in
            guard let self else { return }

            let trimmedIdentifier = identifier?.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
            let hasIdentifier = trimmedIdentifier?.isEmpty == false
            let hasName = trimmedName?.isEmpty == false

            guard hasIdentifier || hasName else {
                // The log stream reports the active mode assertion was cleared
                // (`active mode assertion: (null)`), i.e. Focus was switched off.
                // The `_NSDoNotDisturbDisabledNotification` distributed notification
                // is unreliable on recent macOS, so use this as an additional
                // off signal. publishMetadata only reacts on a real active->inactive
                // transition, so a stale clear is a no-op.
                self.publishMetadata(
                    identifier: nil,
                    name: nil,
                    isActive: false,
                    source: "log-stream-off"
                )
                return
            }

            self.publishMetadata(
                identifier: trimmedIdentifier,
                name: trimmedName,
                isActive: nil,
                source: "log-stream"
            )
        }
    }

    private func checkInitialFocusStateViaLog() {
        metadataExtractionQueue.async { [weak self] in
            guard let self else { return }

            for window in ["5m", "1h", "24h"] {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/log")
                task.arguments = [
                    "show",
                    "--last", window,
                    "--debug",
                    "--style", "compact",
                    "--predicate", "process == \"duetexpertd\" AND eventMessage CONTAINS \"semanticModeIdentifier\""
                ]
                let pipe = Pipe()
                task.standardOutput = pipe
                task.standardError = Pipe()

                guard (try? task.run()) != nil else { return }

                let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
                task.waitUntilExit()

                let output = String(data: outputData, encoding: .utf8) ?? ""
                let lines = output.components(separatedBy: "\n").filter {
                    $0.contains("semanticModeIdentifier") && !$0.hasPrefix("Filtering")
                }

                guard let lastLine = lines.last(where: { !$0.isEmpty }) else { continue }

                guard !lastLine.contains("starting: 0") else { return }

                let identifier = FocusMetadataDecoder.extractIdentifier(from: lastLine)
                let name = FocusMetadataDecoder.extractName(from: lastLine)

                guard identifier != nil || name != nil else { return }

                self.publishMetadata(
                    identifier: identifier,
                    name: name,
                    isActive: true,
                    source: "log-initial"
                )
                return
            }
        }
    }

    private func extractMetadata(from notification: Notification) -> (name: String?, identifier: String?) {
        var identifier: String?
        var name: String?

        let identifierKeys = [
            "FocusModeIdentifier",
            "focusModeIdentifier",
            "FocusModeUUID",
            "focusModeUUID",
            "UUID",
            "uuid",
            "identifier",
            "Identifier"
        ]

        let nameKeys = [
            "FocusModeName",
            "focusModeName",
            "FocusMode",
            "focusMode",
            "displayName",
            "display_name",
            "name",
            "Name"
        ]

        var candidates: [Any] = []
        if let userInfo = notification.userInfo {
            candidates.append(userInfo)
        }

        if let object = notification.object {
            candidates.append(object)
        }

        debugPrint("[DoNotDisturbManager] raw focus payload -> name: \(notification.name.rawValue), object: \(String(describing: notification.object)), userInfo: \(String(describing: notification.userInfo))")

        for candidate in candidates {
            if identifier == nil {
                identifier = firstMatch(for: identifierKeys, in: candidate)
            }

            if name == nil {
                name = firstMatch(for: nameKeys, in: candidate)
            }

            if identifier != nil && name != nil {
                break
            }
        }

        if identifier == nil || name == nil {
            for candidate in candidates {
                if let decoded = decodeFocusPayloadIfNeeded(candidate) {
                    if identifier == nil {
                        identifier = firstMatch(for: identifierKeys, in: decoded)
                    }

                    if name == nil {
                        name = firstMatch(for: nameKeys, in: decoded)
                    }

                    if identifier != nil && name != nil {
                        break
                    }
                }
            }
        }

        if identifier == nil || name == nil {
            for candidate in candidates {
                if let object = candidate as? NSObject {
                    if identifier == nil, let extractedIdentifier = extractIdentifier(fromFocusObject: object) {
                        identifier = extractedIdentifier
                    }

                    if name == nil, let extractedName = extractDisplayName(fromFocusObject: object) {
                        name = extractedName
                    }

                    if identifier != nil && name != nil {
                        break
                    }
                }
            }
        }

        if identifier == nil || name == nil {
            var descriptionSources: [Any] = candidates

            for candidate in candidates {
                if let decoded = decodeFocusPayloadIfNeeded(candidate) {
                    descriptionSources.append(decoded)
                }
            }

            for candidate in descriptionSources {
                let description = String(describing: candidate)

                if identifier == nil, let inferredIdentifier = FocusMetadataDecoder.extractIdentifier(from: description) {
                    identifier = inferredIdentifier
                }

                if name == nil, let inferredName = FocusMetadataDecoder.extractName(from: description) {
                    name = inferredName
                }

                if identifier != nil && name != nil {
                    break
                }
            }
        }

        if identifier == nil || name == nil {
            if let logMetadata = focusLogStream.latestMetadata() {
                if identifier == nil {
                    identifier = logMetadata.identifier
                }

                if name == nil {
                    name = logMetadata.name
                }
            }
        }

        return (name, identifier)
    }

    private func firstMatch(for keys: [String], in value: Any) -> String? {
        if let dictionary = value as? [AnyHashable: Any] {
            for key in keys {
                if let candidate = dictionary[key], let string = normalizedString(from: candidate) {
                    return string
                }
            }

            for nestedValue in dictionary.values {
                if let nestedMatch = firstMatch(for: keys, in: nestedValue) {
                    return nestedMatch
                }
            }
        } else if let array = value as? [Any] {
            for element in array {
                if let nestedMatch = firstMatch(for: keys, in: element) {
                    return nestedMatch
                }
            }
        }

        return nil
    }

    private func normalizedString(from value: Any) -> String? {
        switch value {
        case let string as String:
            let cleaned = FocusMetadataDecoder.cleanedString(string)
            return cleaned.isEmpty ? nil : cleaned
        case let number as NSNumber:
            return FocusMetadataDecoder.cleanedString(number.stringValue)
        case let uuid as UUID:
            return uuid.uuidString
        case let uuid as NSUUID:
            return uuid.uuidString
        case let data as Data:
            if let decoded = decodeFocusPayload(from: data) {
                if let nested = firstMatch(for: ["identifier", "Identifier", "uuid", "UUID"], in: decoded) {
                    return nested
                }
                if let name = firstMatch(for: ["name", "Name", "displayName", "display_name"], in: decoded) {
                    return name
                }
            }
            if let string = String(data: data, encoding: .utf8) {
                let cleaned = FocusMetadataDecoder.cleanedString(string)
                return cleaned.isEmpty ? nil : cleaned
            }
            return nil
        case let dict as [AnyHashable: Any]:
            if let nested = firstMatch(for: ["identifier", "Identifier", "uuid", "UUID"], in: dict) {
                return nested
            }
            if let name = firstMatch(for: ["name", "Name", "displayName", "display_name"], in: dict) {
                return name
            }
            return nil
        default:
            return nil
        }
    }

    private func decodeFocusPayloadIfNeeded(_ value: Any) -> Any? {
        switch value {
        case let data as Data:
            return decodeFocusPayload(from: data)
        case let data as NSData:
            return decodeFocusPayload(from: data as Data)
        default:
            return nil
        }
    }

    private func decodeFocusPayload(from data: Data) -> Any? {
        guard !data.isEmpty else { return nil }

        if let propertyList = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) {
            return propertyList
        }

        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) {
            return jsonObject
        }

        if let string = String(data: data, encoding: .utf8) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        return nil
    }

    private func extractIdentifier(fromFocusObject object: NSObject) -> String? {
        if let array = object as? [Any] {
            for element in array {
                if let nested = element as? NSObject, let identifier = extractIdentifier(fromFocusObject: nested) {
                    return identifier
                }
            }
            return nil
        }

        if let identifier = focusString(object, selector: "modeIdentifier") {
            return identifier
        }

        if let identifier = focusString(object, selector: "identifier") {
            return identifier
        }

        if let details = focusObject(object, selector: "details"), let identifier = extractIdentifier(fromFocusObject: details) {
            return identifier
        }

        if let metadata = focusObject(object, selector: "activeModeAssertionMetadata"), let identifier = extractIdentifier(fromFocusObject: metadata) {
            return identifier
        }

        if let configuration = focusObject(object, selector: "activeModeConfiguration"), let identifier = extractIdentifier(fromFocusObject: configuration) {
            return identifier
        }

        if let modeConfiguration = focusObject(object, selector: "modeConfiguration"), let identifier = extractIdentifier(fromFocusObject: modeConfiguration) {
            return identifier
        }

        if let mode = focusObject(object, selector: "mode") {
            return extractIdentifier(fromFocusObject: mode)
        }

        if let identifiers = focusObject(object, selector: "activeModeIdentifiers") {
            if let stringArray = identifiers as? [String] {
                if let first = stringArray.compactMap({ FocusMetadataDecoder.cleanedString($0) }).first(where: { !$0.isEmpty }) {
                    return first
                }
            } else if let array = identifiers as? NSArray {
                for case let string as String in array {
                    let trimmed = FocusMetadataDecoder.cleanedString(string)
                    if !trimmed.isEmpty {
                        return trimmed
                    }
                }
            }
        }

        return nil
    }

    private func extractDisplayName(fromFocusObject object: NSObject) -> String? {
        if let array = object as? [Any] {
            for element in array {
                if let nested = element as? NSObject, let name = extractDisplayName(fromFocusObject: nested) {
                    return name
                }
            }
            return nil
        }

        if let name = focusString(object, selector: "name") {
            return name
        }

        if let name = focusString(object, selector: "displayName") {
            return name
        }

        if let name = focusString(object, selector: "activityDisplayName") {
            return name
        }

        if let descriptor = focusObject(object, selector: "symbolDescriptor"), let name = focusString(descriptor, selector: "name") {
            return name
        }

        if let mode = focusObject(object, selector: "mode"), let name = extractDisplayName(fromFocusObject: mode) {
            return name
        }

        if let details = focusObject(object, selector: "details"), let name = extractDisplayName(fromFocusObject: details) {
            return name
        }

        if let configuration = focusObject(object, selector: "modeConfiguration"), let name = extractDisplayName(fromFocusObject: configuration) {
            return name
        }

        return nil
    }

    private func focusObject(_ object: NSObject, selector selectorName: String) -> NSObject? {
        let selector = NSSelectorFromString(selectorName)
        guard object.responds(to: selector) else { return nil }
        guard let value = object.perform(selector)?.takeUnretainedValue() else { return nil }
        return value as? NSObject
    }

    private func focusString(_ object: NSObject, selector selectorName: String) -> String? {
        let selector = NSSelectorFromString(selectorName)
        guard object.responds(to: selector) else { return nil }
        guard let value = object.perform(selector)?.takeUnretainedValue() else { return nil }

        switch value {
        case let string as String:
            return FocusMetadataDecoder.cleanedString(string)
        case let string as NSString:
            return FocusMetadataDecoder.cleanedString(string as String)
        case let number as NSNumber:
            return FocusMetadataDecoder.cleanedString(number.stringValue)
        default:
            return nil
        }
    }
}

private extension Notification.Name {
    static let focusModeEnabled = Notification.Name("_NSDoNotDisturbEnabledNotification")
    static let focusModeDisabled = Notification.Name("_NSDoNotDisturbDisabledNotification")
}
