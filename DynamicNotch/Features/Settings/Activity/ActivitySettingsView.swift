//
//  ActivitySettingsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/6/26.
//

import SwiftUI

struct ActivitySettingsView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var notchEventCoordinator: NotchEventCoordinator
    
    var body: some View {
        TabView {
            LiveActivitySettingsView()
                .tabItem{
                    Text("Live Activity")
                }
            
            TemporarySettingsView()
                .tabItem{
                    Text("Temporary Activity")
                }
            
            #if DEBUG
            DebugPanelSettingsView(notchViewModel: notchViewModel, notchEventCoordinator: notchEventCoordinator)
                .tabItem {
                    Text("Debug Panel")
                }
            #endif
        }
        .padding(12)
        .tabViewStyle(.grouped)
        .accessibilityIdentifier("settings.activities.root")
    }
}

private struct LiveActivitySettingsView: View {
    @AppStorage(LockScreenSettings.liveActivityKey) private var isLockScreenLiveActivityEnabled = true
    @AppStorage(LockScreenSettings.mediaPanelKey) private var isLockScreenMediaPanelEnabled = true

    var body: some View {
        Form {
            Section("Lock Screen") {
                Toggle("Show lock screen live activity", isOn: $isLockScreenLiveActivityEnabled)
                    .toggleStyle(CustomToggleStyle())
                    .accessibilityIdentifier("settings.activities.lockScreen.liveActivity")

                Toggle("Show lock screen media panel", isOn: $isLockScreenMediaPanelEnabled)
                    .toggleStyle(CustomToggleStyle())
                    .accessibilityIdentifier("settings.activities.lockScreen.mediaPanel")

                Text("The live activity stays in the notch flow, and the media panel appears on the lock screen when playback is active.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .accessibilityIdentifier("settings.activities.live.content")
    }
}

private struct TemporarySettingsView: View {
    var body: some View {
        Text("pirmer 2")
            .accessibilityIdentifier("settings.activities.temporary.content")
    }
}
