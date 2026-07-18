//
//  SparkleUpdater.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/17/26.
//

import Foundation
import Sparkle
import Combine

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
            .assign(to: &$canCheckForUpdates)
            
        updater.publisher(for: \.automaticallyChecksForUpdates)
            .assign(to: &$automaticallyChecksForUpdates)
            
        updater.publisher(for: \.automaticallyDownloadsUpdates)
            .assign(to: &$automaticallyDownloadsUpdates)
            
        $automaticallyChecksForUpdates
            .dropFirst()
            .sink { [weak updater] newValue in
                updater?.automaticallyChecksForUpdates = newValue
            }
            .store(in: &cancellables)
            
        $automaticallyDownloadsUpdates
            .dropFirst()
            .sink { [weak updater] newValue in
                updater?.automaticallyDownloadsUpdates = newValue
            }
            .store(in: &cancellables)
    }
    
    func checkForUpdates() {
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
}
