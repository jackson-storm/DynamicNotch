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
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        SettingsPageScrollView {
            versionCard
            optionsCard
        }
    }
    
    private var versionCard: some View {
        SettingsCard {
            HStack(spacing: 16) {
                SettingsIconBadge(
                    systemImage: "arrow.clockwise.circle.fill",
                    tint: Color.accentColor,
                    size: 40,
                    iconSize: 20,
                    cornerRadius: 10
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dynamic Notch")
                        .font(.headline)
                    Text("Version \(currentVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    updater.checkForUpdates()
                }) {
                    Text("Check now")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(!updater.canCheckForUpdates)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var optionsCard: some View {
        SettingsCard {
            SettingsToggleRow(
                title: "Automatically check for updates",
                description: "Let Dynamic Notch check for new versions automatically.",
                systemImage: "bell.badge",
                color: .blue,
                isOn: $updater.automaticallyChecksForUpdates,
                accessibilityIdentifier: "settings.update.automaticallyChecks"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Automatically download updates",
                description: "Download updates in the background and notify you when ready.",
                systemImage: "arrow.down.circle",
                color: .green,
                isOn: $updater.automaticallyDownloadsUpdates,
                accessibilityIdentifier: "settings.update.automaticallyDownloads"
            )
            .disabled(!updater.automaticallyChecksForUpdates)
        }
    }
}

