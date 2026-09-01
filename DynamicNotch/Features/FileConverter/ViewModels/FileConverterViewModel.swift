//
//  FileConverterViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/7/26.
//

import Foundation
import Combine
internal import AppKit
import UniformTypeIdentifiers

@MainActor
final class FileConverterViewModel: ObservableObject {
    @Published private(set) var item: FileConverterItem?
    @Published var selectedFormat: FileConverterOutputFormat = .png {
        didSet {
            if status != .idle && status != .converting {
                status = .idle
            }
        }
    }
    @Published private(set) var status: FileConverterStatus = .idle
    
    private let service: FileConverterService
    private var conversionTask: Task<Void, Never>?
    
    var onItemChange: (@MainActor (FileConverterItem?) -> Void)? {
        didSet {
            onItemChange?(item)
        }
    }
    
    var hasItem: Bool {
        item != nil
    }
    
    var isConverting: Bool {
        status == .converting
    }
    
    var isConverted: Bool {
        if case .converted = status {
            return true
        }
        return false
    }
    
    var availableFormats: [FileConverterOutputFormat] {
        guard let item else {
            return FileConverterOutputFormat.formats(for: .image)
        }
        
        return FileConverterOutputFormat.formats(
            for: item.mediaKind,
            isDirectory: item.isDirectory
        )
    }
    
    init(service: FileConverterService) {
        self.service = service
    }

    convenience init() {
        self.init(service: .shared)
    }
    
    func setFile(_ url: URL) throws {
        let standardizedURL = url.standardizedFileURL
        var isDirectory: ObjCBool = false
        
        guard FileManager.default.fileExists(atPath: standardizedURL.path, isDirectory: &isDirectory) else {
            throw NSError(
                domain: "DynamicNotch.FileConverter",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Choose a file or folder to convert."]
            )
        }
        
        let converterItem = FileConverterItem(
            url: standardizedURL,
            mediaKind: service.mediaKind(for: standardizedURL, isDirectory: isDirectory.boolValue),
            isDirectory: isDirectory.boolValue
        )
        item = converterItem
        selectedFormat = service.defaultFormat(for: converterItem)
        status = .idle
        onItemChange?(converterItem)
    }
    
    func convert(options: FileConverterConversionOptions) {
        guard let item, status != .converting else { return }
        
        conversionTask?.cancel()
        status = .converting
        let format = selectedFormat
        
        conversionTask = Task { [weak self, service] in
            do {
                let outputURL = try await service.convert(item: item, to: format, options: options)
                guard !Task.isCancelled else { return }
                self?.handleConversionSuccess(outputURL)
            } catch {
                guard !Task.isCancelled else { return }
                self?.handleConversionFailure(error.localizedDescription)
            }
        }
    }
    
    @MainActor
    func chooseFileFromFinder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.prompt = "Choose"
        panel.message = "Choose a file to convert"
        
        panel.allowedContentTypes = [
            .image,
            .movie,
            .video,
            .audio,
            .archive,
            .zip,
            .folder
        ]
        
        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }
        
        do {
            try setFile(url)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }
    
    func revealConvertedFile() {
        guard case .converted(let outputURL) = status else { return }
        
        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
    }
    
    func clear() {
        conversionTask?.cancel()
        conversionTask = nil
        item = nil
        status = .idle
        onItemChange?(nil)
    }
    
    private func handleConversionSuccess(_ outputURL: URL) {
        conversionTask = nil
        status = .converted(outputURL)
    }

    private func handleConversionFailure(_ message: String) {
        conversionTask = nil
        status = .failed(message)
    }
}

#if DEBUG
extension FileConverterViewModel {
    func showDebugConvertingStatus() {
        conversionTask?.cancel()
        conversionTask = nil
        status = .converting
    }

    func showDebugFailedStatus() {
        conversionTask?.cancel()
        conversionTask = nil
        status = .failed("Debug conversion failed.")
    }
}
#endif
