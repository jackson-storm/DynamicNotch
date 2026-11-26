//
//  AppUpdater.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/17/26.
//

import Foundation
import Combine
internal import AppKit

final class AppUpdater: ObservableObject {
    static let shared = AppUpdater()
    
    static let websiteDownloadURL = URL(string: "https://dynamicnotch.org/#download")!
    private static let githubTagsURL = URL(string: "https://api.github.com/repos/jackson-storm/DynamicNotch/tags")!
    
    private enum StorageKeys {
        static let automaticallyChecksForUpdates = "automaticallyChecksForUpdates"
    }
    
    @Published var canCheckForUpdates = true
    @Published var isCheckingForUpdates = false
    @Published var isUpdateAvailable = false
    @Published var latestVersionString = ""
    @Published var automaticallyChecksForUpdates: Bool {
        didSet {
            UserDefaults.standard.set(automaticallyChecksForUpdates, forKey: StorageKeys.automaticallyChecksForUpdates)
        }
    }
    
    private var checkTimer: Timer?
    private var currentTask: URLSessionDataTask?
    
    private init() {
        if UserDefaults.standard.object(forKey: StorageKeys.automaticallyChecksForUpdates) == nil {
            self.automaticallyChecksForUpdates = true
        } else {
            self.automaticallyChecksForUpdates = UserDefaults.standard.bool(forKey: StorageKeys.automaticallyChecksForUpdates)
        }
        
        startAutomaticCheckOnLaunch()
        startPeriodicCheckTimer()
    }
    
    deinit {
        checkTimer?.invalidate()
        currentTask?.cancel()
    }
    
    func startPeriodicCheckTimer() {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 600.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.automaticallyChecksForUpdates {
                self.checkForUpdatesInBackground()
            }
        }
    }
    
    func startAutomaticCheckOnLaunch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            if self.automaticallyChecksForUpdates {
                self.checkForUpdatesInBackground()
            }
        }
    }
    
    func checkForUpdates(userInitiated: Bool = true) {
        if userInitiated && isUpdateAvailable {
            openDownloadPage()
            return
        }
        
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true
        
        performCheck { [weak self] result in
            guard let self = self else { return }
            self.isCheckingForUpdates = false
            
            switch result {
            case .success(let update):
                if let update = update {
                    self.latestVersionString = update
                    self.isUpdateAvailable = true
                    if userInitiated {
                        self.openDownloadPage()
                    }
                } else {
                    self.isUpdateAvailable = false
                    if userInitiated {
                        self.showUpToDateAlert()
                    }
                }
            case .failure(let error):
                if userInitiated {
                    self.showErrorAlert(error)
                }
            }
        }
    }
    
    func checkForUpdatesInBackground() {
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true
        
        performCheck { [weak self] result in
            guard let self = self else { return }
            self.isCheckingForUpdates = false
            
            if case .success(let update) = result {
                if let update = update {
                    self.latestVersionString = update
                    self.isUpdateAvailable = true
                } else {
                    self.isUpdateAvailable = false
                }
            }
        }
    }
    
    func openDownloadPage() {
        NSWorkspace.shared.open(Self.websiteDownloadURL)
    }
    
    private func performCheck(completion: @escaping @Sendable (Result<String?, Error>) -> Void) {
        currentTask?.cancel()
        
        var request = URLRequest(url: Self.githubTagsURL)
        request.httpMethod = "GET"
        request.setValue("DynamicNotch-App", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15.0
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                return
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.success(nil))
                }
                return
            }
            
            do {
                let tags = try JSONDecoder().decode([GitHubTag].self, from: data)
                let latestTag = tags.first?.name
                let currentVersion = self?.currentAppVersion ?? "1.0.0"
                
                let isNewer = self?.compareVersions(latest: latestTag, current: currentVersion) ?? false
                
                DispatchQueue.main.async {
                    if isNewer, let tag = latestTag {
                        let cleanVersion = tag.hasPrefix("v") || tag.hasPrefix("V") ? String(tag.dropFirst()) : tag
                        completion(.success(cleanVersion))
                    } else {
                        completion(.success(nil))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        currentTask = task
        task.resume()
    }
    
    var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    func compareVersions(latest: String?, current: String) -> Bool {
        guard let latest = latest else { return false }
        
        let cleanLatest = (latest.hasPrefix("v") || latest.hasPrefix("V")) ? String(latest.dropFirst()) : latest
        let cleanCurrent = (current.hasPrefix("v") || current.hasPrefix("V")) ? String(current.dropFirst()) : current
        
        let latestComponents = cleanLatest.split(separator: ".").compactMap { Int($0) }
        let currentComponents = cleanCurrent.split(separator: ".").compactMap { Int($0) }
        
        let maxCount = max(latestComponents.count, currentComponents.count)
        for i in 0..<maxCount {
            let latestValue = i < latestComponents.count ? latestComponents[i] : 0
            let currentValue = i < currentComponents.count ? currentComponents[i] : 0
            
            if latestValue > currentValue {
                return true
            } else if latestValue < currentValue {
                return false
            }
        }
        
        return false
    }
    
    private func showUpToDateAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("update.upToDate.title", value: "You're up to date!", comment: "")
        alert.informativeText = String(
            format: NSLocalizedString("update.upToDate.message", value: "DynamicNotch %@ is currently the latest version.", comment: ""),
            currentAppVersion
        )
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("update.ok", value: "OK", comment: ""))
        alert.runModal()
    }
    
    private func showErrorAlert(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("update.error.title", value: "Check for Updates Failed", comment: "")
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("update.ok", value: "OK", comment: ""))
        alert.runModal()
    }
}

// Compatibility typealias so existing references continue to work seamlessly
typealias SparkleUpdater = AppUpdater

private struct GitHubTag: Decodable {
    let name: String
}
