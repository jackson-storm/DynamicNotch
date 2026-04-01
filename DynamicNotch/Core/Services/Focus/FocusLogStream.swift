import Foundation

final class FocusLogStream {
    private let queue = DispatchQueue(
        label: "com.dynamicisland.focus.logstream",
        qos: .utility
    )
    private var process: Process?
    private var pipe: Pipe?
    private var buffer = Data()
    private var isRunning = false

    private let metadataLock = NSLock()
    private var lastIdentifier: String?
    private var lastName: String?

    var onMetadataUpdate: ((String?, String?) -> Void)?

    func start() {
        queue.async { [weak self] in
            guard let self else { return }
            guard !self.isRunning else { return }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/log")
            process.arguments = [
                "stream",
                "--style",
                "compact",
                "--level",
                "info",
                "--predicate",
                "subsystem == \"com.apple.focus\""
            ]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                guard let self else { return }
                let data = handle.availableData

                if data.isEmpty {
                    self.queue.async { [weak self] in
                        self?.handleTermination()
                    }
                    return
                }

                self.queue.async { [weak self] in
                    self?.handleIncomingData(data)
                }
            }

            process.terminationHandler = { [weak self] _ in
                self?.queue.async {
                    self?.handleTermination()
                }
            }

            do {
                try process.run()
                self.process = process
                self.pipe = pipe
                self.isRunning = true
                debugPrint("[FocusLogStream] Started unified log tail for com.apple.focus")
            } catch {
                debugPrint("[FocusLogStream] Failed to start log stream: \(error)")
                pipe.fileHandleForReading.readabilityHandler = nil
                self.process = nil
                self.pipe = nil
            }
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            guard self.isRunning else { return }
            self.handleTermination(terminateProcess: true)
        }
    }

    func latestMetadata() -> (identifier: String?, name: String?)? {
        metadataLock.lock()
        let identifier = lastIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = lastName?.trimmingCharacters(in: .whitespacesAndNewlines)
        metadataLock.unlock()

        let normalizedIdentifier = identifier?.isEmpty == false ? identifier : nil
        let normalizedName = name?.isEmpty == false ? name : nil

        if normalizedIdentifier == nil && normalizedName == nil {
            return nil
        }

        return (normalizedIdentifier, normalizedName)
    }

    private func handleIncomingData(_ data: Data) {
        buffer.append(data)

        let newline: UInt8 = 0x0A

        while let newlineIndex = buffer.firstIndex(of: newline) {
            let lineData = buffer.prefix(upTo: newlineIndex)
            buffer.removeSubrange(buffer.startIndex...newlineIndex)

            let trimmedLineData: Data
            if let lastByte = lineData.last, lastByte == 0x0D {
                trimmedLineData = lineData.dropLast()
            } else {
                trimmedLineData = lineData
            }

            guard !trimmedLineData.isEmpty,
                  let line = String(data: trimmedLineData, encoding: .utf8) else {
                continue
            }

            processLine(line)
        }
    }

    private func processLine(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if trimmed.hasPrefix("Filtering the log data") || trimmed.hasPrefix("Timestamp") {
            return
        }

        if trimmed.contains("active mode assertion: (null)") ||
            trimmed.contains("active activity: (null)") {
            clearMetadata()
            return
        }

        var updatedIdentifier: String?
        var updatedName: String?

        if let identifier = FocusMetadataDecoder.extractIdentifier(from: trimmed), !identifier.isEmpty {
            updatedIdentifier = identifier
        }

        if let name = FocusMetadataDecoder.extractName(from: trimmed), !name.isEmpty {
            updatedName = name
        }

        guard updatedIdentifier != nil || updatedName != nil else { return }

        var identifierToSend: String?
        var nameToSend: String?

        metadataLock.lock()
        if let identifier = updatedIdentifier, !identifier.isEmpty {
            lastIdentifier = identifier
        }

        if let name = updatedName, !name.isEmpty {
            lastName = name
        }

        identifierToSend = lastIdentifier
        nameToSend = lastName
        metadataLock.unlock()

        notifyMetadataUpdate(identifier: identifierToSend, name: nameToSend)
    }

    private func clearMetadata() {
        metadataLock.lock()
        lastIdentifier = nil
        lastName = nil
        metadataLock.unlock()
        notifyMetadataUpdate(identifier: nil, name: nil)
    }

    private func handleTermination(terminateProcess: Bool = false) {
        if terminateProcess, let process, process.isRunning {
            process.terminate()
        }

        pipe?.fileHandleForReading.readabilityHandler = nil
        pipe?.fileHandleForReading.closeFile()
        pipe = nil

        process = nil
        buffer.removeAll(keepingCapacity: false)
        isRunning = false
        clearMetadata()
        debugPrint("[FocusLogStream] Stopped unified log tail for com.apple.focus")
    }

    private func notifyMetadataUpdate(identifier: String?, name: String?) {
        guard let handler = onMetadataUpdate else { return }
        handler(identifier, name)
    }
}
