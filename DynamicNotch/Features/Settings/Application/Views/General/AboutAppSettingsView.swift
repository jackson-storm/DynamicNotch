//
//  AboutApp.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/6/26.
//

import SwiftUI

struct AboutAppSettingsView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    let onRequestInternetAccess: () -> Bool
    
    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        
        switch (version) {
        case let (version?):
            return "v\(version)"
        default:
            return "DynamicNotch"
        }
    }
    
    var body: some View {
        SettingsPageScrollView {
            headerCard
            socialLinksCard
        }
        .edgesIgnoringSafeArea(.top)
        .accessibilityIdentifier("settings.about.root")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Text(appVersionText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
            }
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            Image("logo")
                .resizable()
                .frame(width: 80, height: 80)
                .shadow(color: .purple, radius: 30)
                .padding(.top, 80)
            
            VStack(spacing: 8) {
                Text("DynamicNotch")
                    .font(.system(size: 20, weight: .bold))
                
                Text("settings.permissions.page.subtitle")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
            }
        }
    }
    
    private var socialLinksCard: some View {
        SettingsCard(spacing: 0, padding: 0) {
            SettingsUrlRowView(
                title: "Telegram Channel",
                description: "Join our Telegram channel",
                imageName: "telegram",
                color: .clear,
                position: .first,
                url: "https://t.me/Dynamic_Notch",
                onRequestInternetAccess: onRequestInternetAccess
            )
            
            SettingsUrlRowView(
                title: "GitHub Repository",
                description: "Star the project on GitHub",
                imageName: "gitHub",
                color: .clear,
                position: .middle,
                url: "https://github.com/jackson-storm/DynamicNotch",
                onRequestInternetAccess: onRequestInternetAccess
            )
            
            SettingsUrlRowView(
                title: "Website",
                description: "Open the DynamicNotch website",
                imageName: "simplifiedLogo",
                color: .clear,
                position: .last,
                url: "https://dynamicnotch.evgeniy-petrukovich.workers.dev",
                onRequestInternetAccess: onRequestInternetAccess
            )
        }
    }
    
    private func open(_ value: String) {
        guard let url = URL(string: value) else { return }
        openInternetURL(url)
    }
    
    private func openInternetURL(_ url: URL) {
        guard onRequestInternetAccess() else { return }
        openURL(url)
    }
}
