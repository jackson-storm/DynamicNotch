//
//  SparkleUpdater.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/17/26.
//

import Foundation
import Sparkle
import Combine
internal import AppKit

final class SparkleUpdater: NSObject, ObservableObject, SPUUpdaterDelegate {
    static let shared = SparkleUpdater()
    
    private var updaterController: SPUStandardUpdaterController!
    
    @Published var canCheckForUpdates = false
    @Published var automaticallyChecksForUpdates = false
    @Published var automaticallyDownloadsUpdates = false
    @Published var isUpdateAvailable = false
    @Published var latestVersionString = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
        
        let updater = updaterController.updater
        
        updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                if self?.canCheckForUpdates != newValue {
                    self?.canCheckForUpdates = newValue
                }
            }
            .store(in: &cancellables)
            
        updater.publisher(for: \.automaticallyChecksForUpdates)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                if self?.automaticallyChecksForUpdates != newValue {
                    self?.automaticallyChecksForUpdates = newValue
                }
            }
            .store(in: &cancellables)
            
        updater.publisher(for: \.automaticallyDownloadsUpdates)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                if self?.automaticallyDownloadsUpdates != newValue {
                    self?.automaticallyDownloadsUpdates = newValue
                }
            }
            .store(in: &cancellables)
            
        $automaticallyChecksForUpdates
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak updater] newValue in
                if updater?.automaticallyChecksForUpdates != newValue {
                    updater?.automaticallyChecksForUpdates = newValue
                }
            }
            .store(in: &cancellables)
            
        $automaticallyDownloadsUpdates
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak updater] newValue in
                if updater?.automaticallyDownloadsUpdates != newValue {
                    updater?.automaticallyDownloadsUpdates = newValue
                }
            }
            .store(in: &cancellables)
        
        updater.updateCheckInterval = 600
        
        startAutomaticCheckOnLaunch()
        startPeriodicCheckTimer()
    }
    
    private var checkTimer: Timer?
    
    private func startPeriodicCheckTimer() {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 600.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.automaticallyChecksForUpdates {
                self.updaterController.updater.checkForUpdatesInBackground()
            }
        }
    }
    
    func startAutomaticCheckOnLaunch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            if self.automaticallyChecksForUpdates {
                self.updaterController.updater.checkForUpdatesInBackground()
            }
        }
    }
    
    func checkForUpdates() {
        NSApp.activate(ignoringOtherApps: true)
        updaterController.checkForUpdates(nil)
    }
  
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        DispatchQueue.main.async {
            self.latestVersionString = item.displayVersionString
            self.isUpdateAvailable = true
        }
    }
    
    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        DispatchQueue.main.async {
            self.isUpdateAvailable = false
        }
    }
    
    func updater(_ updater: SPUUpdater, willInstallUpdateOnQuit item: SUAppcastItem, immediateInstallationBlock immediateInstallHandler: @escaping () -> Void) -> Bool {
        DispatchQueue.main.async {
            self.isUpdateAvailable = false
        }
        return false
    }
    
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        print("Sparkle update error: \(error.localizedDescription)")
    }
}
