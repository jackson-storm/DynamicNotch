//
//  AirDropController.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/24/26.
//

import SwiftUI
internal import AppKit
import Combine
import UniformTypeIdentifiers

@MainActor
final class NotchAirDropController: NSObject, ObservableObject {
    @Published var isTargeted = false {
        didSet {
            guard oldValue != isTargeted else { return }

            if suppressTargetResetEvent && !isTargeted {
                suppressTargetResetEvent = false
                return
            }

            airDropViewModel.setDraggingFile(isTargeted)
        }
    }

    private let airDropViewModel: AirDropNotchViewModel
    private let fileTrayViewModel: FileTrayViewModel
    private var activeShares: [UUID: NotchAirDropShareSession] = [:]
    private var suppressTargetResetEvent = false

    init(
        airDropViewModel: AirDropNotchViewModel,
        fileTrayViewModel: FileTrayViewModel
    ) {
        self.airDropViewModel = airDropViewModel
        self.fileTrayViewModel = fileTrayViewModel
        super.init()
    }

    func handlePasteboardDrop(_ pasteboard: NSPasteboard) -> Bool {
        guard let fileURLs = pasteboard.fileURLsForAirDrop(), !fileURLs.isEmpty else {
            return false
        }

        Task.detached(priority: .userInitiated) { [fileURLs] in
            do {
                let batch = try ResolvedAirDropBatch.make(from: fileURLs)

                await MainActor.run {
                    self.suppressTargetResetEvent = true
                    self.isTargeted = false
                    self.airDropViewModel.handleSuccessfulDrop()
                    self.beginShare(with: batch)
                }
            } catch {
                await MainActor.run {
                    self.isTargeted = false
                    self.present(error: error)
                }
            }
        }

        return true
    }

    func handleTrayDrop(_ pasteboard: NSPasteboard) -> Bool {
        guard let fileURLs = pasteboard.fileURLsForAirDrop(), !fileURLs.isEmpty else {
            return false
        }

        fileTrayViewModel.add(fileURLs)
        suppressTargetResetEvent = true
        isTargeted = false
        airDropViewModel.handleSuccessfulDrop()
        return true
    }

    func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard !providers.isEmpty else { return false }

        Task.detached(priority: .userInitiated) { [providers] in
            do {
                let batch = try await providers.resolveAirDropBatch()

                await MainActor.run {
                    self.suppressTargetResetEvent = true
                    self.isTargeted = false
                    self.airDropViewModel.handleSuccessfulDrop()
                    self.beginShare(with: batch)
                }
            } catch {
                await MainActor.run {
                    self.isTargeted = false
                    self.present(error: error)
                }
            }
        }

        return true
    }

    private func beginShare(with batch: ResolvedAirDropBatch) {
        let identifier = UUID()
        let session = NotchAirDropShareSession(batch: batch) { [weak self] in
            self?.activeShares.removeValue(forKey: identifier)
        }

        activeShares[identifier] = session
        session.begin()
    }

    private func present(error: Error) {
        NSApp.activate(ignoringOtherApps: true)
        NSAlert(error: error).runModal()
    }
}

private final class NotchAirDropShareSession: NSObject, NSSharingServiceDelegate {
    private let batch: ResolvedAirDropBatch
    private let onFinish: () -> Void
    private var hasFinished = false

    init(batch: ResolvedAirDropBatch, onFinish: @escaping () -> Void) {
        self.batch = batch
        self.onFinish = onFinish
        super.init()
    }

    func begin() {
        do {
            try send(batch.urls)

            DispatchQueue.main.asyncAfter(deadline: .now() + 600) { [weak self] in
                self?.finish()
            }
        } catch {
            present(error: error)
            finish()
        }
    }

    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        finish()
    }

    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        present(error: error)
        finish()
    }

    private func send(_ files: [URL]) throws {
        guard let service = NSSharingService(named: .sendViaAirDrop) else {
            throw NSError(
                domain: "DynamicNotch.AirDrop",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "AirDrop service is not available on this Mac."]
            )
        }

        guard service.canPerform(withItems: files) else {
            throw NSError(
                domain: "DynamicNotch.AirDrop",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "These items cannot be shared via AirDrop."]
            )
        }

        service.delegate = self
        NSApp.activate(ignoringOtherApps: true)
        service.perform(withItems: files)
    }

    private func present(error: Error) {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            NSAlert(error: error).runModal()
        }
    }

    private func finish() {
        guard !hasFinished else { return }
        hasFinished = true

        try? FileManager.default.removeItem(at: batch.temporaryDirectory)
        onFinish()
    }
}

private struct ResolvedAirDropBatch {
    let urls: [URL]
    let temporaryDirectory: URL

    nonisolated static func make(from sourceURLs: [URL]) throws -> ResolvedAirDropBatch {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DynamicNotch")
            .appendingPathComponent("AirDrop")
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )

        var copiedURLs: [URL] = []
        copiedURLs.reserveCapacity(sourceURLs.count)

        for (index, sourceURL) in sourceURLs.enumerated() {
            let destinationURL = uniqueDestinationURL(
                in: temporaryDirectory,
                preferredName: sourceURL.lastPathComponent,
                fallbackIndex: index
            )

            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            copiedURLs.append(destinationURL)
        }

        return ResolvedAirDropBatch(urls: copiedURLs, temporaryDirectory: temporaryDirectory)
    }

    nonisolated private static func uniqueDestinationURL(in directory: URL, preferredName: String, fallbackIndex: Int) -> URL {
        let baseName = (preferredName as NSString).deletingPathExtension
        let pathExtension = (preferredName as NSString).pathExtension
        let sanitizedBaseName = baseName.isEmpty ? "DroppedFile-\(fallbackIndex + 1)" : baseName
        var candidate = directory.appendingPathComponent(preferredName, isDirectory: false)
        var suffix = 1

        while FileManager.default.fileExists(atPath: candidate.path) {
            let suffixedName = "\(sanitizedBaseName)-\(suffix)"
            candidate = directory.appendingPathComponent(suffixedName)

            if !pathExtension.isEmpty {
                candidate.appendPathExtension(pathExtension)
            }

            suffix += 1
        }

        return candidate
    }
}

extension NSPasteboard {
    var isFileTrayLocalDrag: Bool {
        availableType(from: [FileTrayPasteboard.localDragPasteboardType]) != nil ||
        pasteboardItems?.contains {
            $0.data(forType: FileTrayPasteboard.localDragPasteboardType) != nil
        } == true
    }

    var containsAirDropFiles: Bool {
        fileURLsForAirDrop()?.isEmpty == false
    }

    func fileURLsForAirDrop() -> [URL]? {
        let readOptions: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true
        ]

        if let urls = readObjects(forClasses: [NSURL.self], options: readOptions) as? [URL],
           !urls.isEmpty {
            return urls.filter(\.isFileURL)
        }

        let pasteboardItemURLs = pasteboardItems?.compactMap { item in
            if let string = item.string(forType: .fileURL),
               let url = URL(string: string),
               url.isFileURL {
                return url
            }

            if let string = item.string(forType: .URL),
               let url = URL(string: string),
               url.isFileURL {
                return url
            }

            return nil
        }

        if let pasteboardItemURLs, !pasteboardItemURLs.isEmpty {
            return pasteboardItemURLs
        }

        return nil
    }
}

private extension Array where Element == NSItemProvider {
    func resolveAirDropBatch() async throws -> ResolvedAirDropBatch {
        var sourceURLs: [URL] = []
        sourceURLs.reserveCapacity(count)

        for (index, provider) in enumerated() {
            guard let resolvedURL = try await provider.resolveAirDropFileURL(
                fallbackIndex: index
            ) else {
                throw NSError(
                    domain: "DynamicNotch.AirDrop",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "One or more dropped files could not be loaded."]
                )
            }

            sourceURLs.append(resolvedURL)
        }

        return try ResolvedAirDropBatch.make(from: sourceURLs)
    }
}

private extension NSItemProvider {
    func resolveAirDropFileURL(fallbackIndex: Int) async throws -> URL? {
        if let existingFileURL = try await loadPreferredFileURL() {
            return existingFileURL
        }

        if let promisedFileURL = try await loadPromisedFileURL() {
            return promisedFileURL
        }

        return nil
    }

    private func loadPreferredFileURL() async throws -> URL? {
        if hasItemConformingToTypeIdentifier(UTType.fileURL.identifier),
           let fileURL = try await loadItemURL(forTypeIdentifier: UTType.fileURL.identifier) {
            return fileURL
        }

        if let objectURL = try await loadObjectURL() {
            return objectURL
        }

        if hasItemConformingToTypeIdentifier(UTType.item.identifier) {
            return try await loadItemURL(forTypeIdentifier: UTType.item.identifier)
        }

        return nil
    }

    private func loadPromisedFileURL() async throws -> URL? {
        guard hasItemConformingToTypeIdentifier(UTType.data.identifier) else {
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            loadInPlaceFileRepresentation(forTypeIdentifier: UTType.data.identifier) { url, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: url)
                }
            }
        }
    }

    private func loadObjectURL() async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            _ = loadObject(ofClass: URL.self) { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: url)
                }
            }
        }
    }

    private func loadItemURL(forTypeIdentifier typeIdentifier: String) async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: Self.makeURL(from: item))
            }
        }
    }

    private static func makeURL(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }

        if let data = item as? Data {
            if let string = String(data: data, encoding: .utf8) {
                if let url = URL(string: string) {
                    return url
                }

                if string.hasPrefix("/") {
                    return URL(fileURLWithPath: string)
                }
            }
        }

        if let string = item as? String {
            if let url = URL(string: string) {
                return url
            }

            if string.hasPrefix("/") {
                return URL(fileURLWithPath: string)
            }
        }

        return nil
    }
}
