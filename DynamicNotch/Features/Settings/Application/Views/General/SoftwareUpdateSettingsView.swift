//
//  SoftwareUpdateSettingsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/13/26.
//

import SwiftUI

struct SoftwareUpdateSettingsView: View {
    @ObservedObject private var updater = SparkleUpdater.shared
    
    private var currentVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return "\(version)"
    }
    
    var body: some View {
        SettingsPageScrollView {
            versionCard
            optionsCard
        }
    }
    
    private var versionCard: some View {
        SettingsCard {
            SettingsButtonRow(
                title: "DynamicNotch",
                description: "Version \(currentVersion)",
                imageName: "simplifiedLogo",
                iconSize: 30,
                color: .clear,
                buttonTitle: "settings.update.checkNow",
                isButtonDisabled: !updater.canCheckForUpdates,
                accessibilityIdentifier: "settings.update.versionCard"
            ) {
                updater.checkForUpdates()
            }
        }
    }
    
    private var optionsCard: some View {
        SettingsCard {
            SettingsToggleRow(
                title: "settings.update.autoCheck.title",
                description: "settings.update.autoCheck.desc",
                systemImage: "bell.badge.fill",
                color: .red,
                isOn: $updater.automaticallyChecksForUpdates,
                accessibilityIdentifier: "settings.update.automaticallyChecks"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "settings.update.autoDownload.title",
                description: "settings.update.autoDownload.desc",
                systemImage: "arrow.down.circle.dotted",
                color: .blue,
                isOn: $updater.automaticallyDownloadsUpdates,
                accessibilityIdentifier: "settings.update.automaticallyDownloads"
            )
            .disabled(!updater.automaticallyChecksForUpdates)
            .opacity(!updater.automaticallyChecksForUpdates ? 0.5 : 1)
        }
    }
}

