import Combine
import Foundation

@MainActor
final class ClipboardHistoryViewModel: ObservableObject {
    static let historyLimitRange = 5...50
    static let maximumHistoryBytes = 32 * 1_024 * 1_024

    @Published private(set) var items: [ClipboardHistoryItem] = []
    @Published private(set) var currentItemID: UUID?
    @Published private(set) var restoreFailure: ClipboardRestoreFailure?
    @Published var event: ClipboardEvent?

    var onWillRestore: (() -> Void)?
    var onDidCapture: ((ClipboardHistoryItem) -> Void)?

    private let monitor: ClipboardMonitoring
    private let fileExists: (URL) -> Bool
    private var historyLimit: Int
    private var restoreFailureTask: Task<Void, Never>?

    init(
        monitor: ClipboardMonitoring,
        historyLimit: Int = 20,
        fileExists: @escaping (URL) -> Bool = { FileManager.default.fileExists(atPath: $0.path) }
    ) {
        self.monitor = monitor
        self.fileExists = fileExists
        self.historyLimit = Self.clampedHistoryLimit(historyLimit)
        monitor.onClipboardChange = { [weak self] snapshot in
            self?.receive(snapshot)
        }
    }

    deinit {
        restoreFailureTask?.cancel()
    }

    func startMonitoring() {
        monitor.startMonitoring()
    }

    func stopMonitoring() {
        monitor.stopMonitoring()
    }

    func updateHistoryLimit(_ limit: Int) {
        historyLimit = Self.clampedHistoryLimit(limit)
        trimHistoryIfNeeded()
    }

    @discardableResult
    func restore(_ item: ClipboardHistoryItem) -> Bool {
        guard items.contains(where: { $0.id == item.id }) else { return false }
        if case .files(let urls) = item.payload,
           urls.contains(where: { !fileExists($0) }) {
            showRestoreFailure(
                for: item,
                message: urls.count == 1 ?
                    "The original file is no longer available." :
                    "One or more original files are no longer available."
            )
            return false
        }

        onWillRestore?()
        guard monitor.write(item.payload) else {
            showRestoreFailure(for: item, message: "Couldn’t copy this item again.")
            return false
        }

        currentItemID = item.id
        clearRestoreFailure()
        return true
    }

    func remove(_ item: ClipboardHistoryItem) {
        items.removeAll { $0.id == item.id }
        if currentItemID == item.id {
            currentItemID = nil
        }
        if restoreFailure?.itemID == item.id {
            clearRestoreFailure()
        }
    }

    func clearHistory() {
        clearRestoreFailure()
        items.removeAll()
        currentItemID = nil
        event = nil
    }

    private func receive(_ snapshot: ClipboardSnapshot) {
        items.removeAll { $0.payload == snapshot.payload }

        let item = ClipboardHistoryItem(
            payload: snapshot.payload,
            sourceApplicationName: snapshot.sourceApplicationName,
            capturedAt: snapshot.capturedAt
        )
        items.insert(item, at: 0)
        currentItemID = item.id
        clearRestoreFailure()
        trimHistoryIfNeeded()
        onDidCapture?(item)
        event = .captured(item)
    }

    private func trimHistoryIfNeeded() {
        if items.count > historyLimit {
            items.removeLast(items.count - historyLimit)
        }

        var retainedBytes = 0
        var retainedCount = 0
        for item in items {
            let nextBytes = retainedBytes + item.payload.estimatedByteCount
            guard retainedCount == 0 || nextBytes <= Self.maximumHistoryBytes else { break }
            retainedBytes = nextBytes
            retainedCount += 1
        }
        if retainedCount < items.count {
            items.removeLast(items.count - retainedCount)
        }

        let retainedIDs = Set(items.map(\.id))
        if let currentItemID, !retainedIDs.contains(currentItemID) {
            self.currentItemID = nil
        }
        if let failure = restoreFailure, !retainedIDs.contains(failure.itemID) {
            clearRestoreFailure()
        }
    }

    private func showRestoreFailure(for item: ClipboardHistoryItem, message: String) {
        restoreFailureTask?.cancel()
        let failure = ClipboardRestoreFailure(itemID: item.id, message: message)
        restoreFailure = failure
        restoreFailureTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled, self?.restoreFailure == failure else { return }
            self?.restoreFailure = nil
        }
    }

    private func clearRestoreFailure() {
        restoreFailureTask?.cancel()
        restoreFailureTask = nil
        restoreFailure = nil
    }

    private static func clampedHistoryLimit(_ limit: Int) -> Int {
        min(max(limit, historyLimitRange.lowerBound), historyLimitRange.upperBound)
    }
}
