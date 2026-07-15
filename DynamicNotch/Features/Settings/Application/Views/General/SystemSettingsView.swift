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
                title: "Launch at login",
                description: "Launch Dynamic Notch automatically when you sign in.",
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
                title: "Show Dock icon",
                description: "Keep the app visible in the Dock for faster switching and window access.",
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
                    title: "Show menu bar icon",
                    description: "Show a menu bar shortcut for quick access to Settings and Quit.",
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
                        
                        Text("You can access the menu by right-clicking on the notch area.")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
    }
}
