//
//  FileTrayViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/26/26.
//

import Foundation
import Combine
internal import AppKit

enum FileTrayPasteboard {
    static let localDragTypeIdentifier = "com.dynamicnotch.file-tray.local-drag"
    static let localDragPasteboardType = NSPasteboard.PasteboardType(localDragTypeIdentifier)
}

final class FileTrayPasteboardWriter: NSObject, NSPasteboardWriting {
    private let url: URL

    init(url: URL) {
        self.url = url.standardizedFileURL
    }

    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        [
            .fileURL,
            .URL,
            FileTrayPasteboard.localDragPasteboardType
        ]
    }

    func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        switch type {
        case .fileURL, .URL:
            return url.absoluteString
        case FileTrayPasteboard.localDragPasteboardType:
            return Data([1])
        default:
            return nil
        }
    }
}

struct FileTrayItem: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let displayName: String
    let isDirectory: Bool

    init(url: URL, id: UUID = UUID()) {
        let standardizedURL = url.standardizedFileURL
        var isDirectoryValue: ObjCBool = false

        FileManager.default.fileExists(
            atPath: standardizedURL.path,
            isDirectory: &isDirectoryValue
        )

        self.id = id
        self.url = standardizedURL
        self.displayName = standardizedURL.lastPathComponent.isEmpty ?
            standardizedURL.deletingLastPathComponent().lastPathComponent :
            standardizedURL.lastPathComponent
        self.isDirectory = isDirectoryValue.boolValue
    }

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }

    var itemProvider: NSItemProvider {
        let provider = NSItemProvider(object: url as NSURL)
        provider.suggestedName = displayName
        provider.registerDataRepresentation(
            forTypeIdentifier: FileTrayPasteboard.localDragTypeIdentifier,
            visibility: .ownProcess
        ) { completion in
            completion(Data([1]), nil)
            return nil
        }
        return provider
    }
}

@MainActor
final class FileTrayViewModel: ObservableObject {
    @Published var selectedItemIDs: Set<FileTrayItem.ID> = []
    @Published private(set) var items: [FileTrayItem] = []

    var onItemsChange: (([FileTrayItem]) -> Void)?

    var count: Int {
        items.count
    }

    var selectedCount: Int {
        selectedItems.count
    }

    var hasSelection: Bool {
        selectedItemIDs.isEmpty == false
    }

    var selectedItems: [FileTrayItem] {
        items.filter { selectedItemIDs.contains($0.id) }
    }

    func add(_ urls: [URL]) {
        var knownIdentities = Set(items.map { Self.identity(for: $0.url) })
        let newItems = urls.compactMap { url -> FileTrayItem? in
            let standardizedURL = url.standardizedFileURL
            guard standardizedURL.isFileURL else { return nil }

            let identity = Self.identity(for: standardizedURL)
            guard knownIdentities.insert(identity).inserted else { return nil }

            return FileTrayItem(url: standardizedURL)
        }

        guard !newItems.isEmpty else { return }

        updateItems(items + newItems)
    }

    func toggleSelection(for item: FileTrayItem) {
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }
    
    func selectAll() {
        selectedItemIDs = Set(items.map { $0.id })
    }

    func clearSelection() {
        selectedItemIDs.removeAll()
    }

    func itemsForDrag(startingAt item: FileTrayItem) -> [FileTrayItem] {
        if selectedItemIDs.contains(item.id) {
            return selectedItems
        }

        return [item]
    }

    func remove(_ item: FileTrayItem) {
        updateItems(items.filter { $0.id != item.id })
    }

    func removeSelectedItems() {
        guard hasSelection else { return }
        updateItems(items.filter { selectedItemIDs.contains($0.id) == false })
    }

    func clear() {
        updateItems([])
    }

    private func updateItems(_ newItems: [FileTrayItem]) {
        items = newItems
        selectedItemIDs.formIntersection(Set(newItems.map(\.id)))
        onItemsChange?(newItems)
    }

    private static func identity(for url: URL) -> String {
        url.resolvingSymlinksInPath().standardizedFileURL.path
    }
}

