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
    var body: some View {
        Text("primer")
            .accessibilityIdentifier("settings.activities.live.content")
    }
}

private struct TemporarySettingsView: View {
    var body: some View {
        Text("pirmer 2")
            .accessibilityIdentifier("settings.activities.temporary.content")
    }
}
