//
//  SystemSettingsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/15/26.
//

import SwiftUI

struct SystemSettingsView: View {
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            systemCard
        }
    }
    
    private var systemCard: some View {
        SettingsCard() {
            SettingsToggleRow(
                title: "settings.system.launchAtLogin.title",
                description: "settings.system.launchAtLogin.desc",
                systemImage: "power",
                color: .red,
                isOn: $applicationSettings.isLaunchAtLoginEnabled,
                accessibilityIdentifier: "settings.general.launchAtLogin"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "settings.system.dockIcon.title",
                description: "settings.system.dockIcon.desc",
                systemImage: "dock.rectangle",
                color: .orange,
                isOn: $applicationSettings.isDockIconVisible,
                accessibilityIdentifier: "settings.general.dockIcon"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            VStack(alignment: .leading, spacing: 14) {
                SettingsToggleRow(
                    title: "settings.system.menuBarIcon.title",
                    description: "settings.system.menuBarIcon.desc",
                    systemImage: "menubar.rectangle",
                    color: .blue,
                    isOn: $applicationSettings.isMenuBarIconVisible,
                    accessibilityIdentifier: "settings.general.menuBarIcon"
                )
                if !applicationSettings.isMenuBarIconVisible {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.yellow)
                        
                        Text(LocalizedStringKey("settings.system.menuBarIcon.warning"))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
    }
}
