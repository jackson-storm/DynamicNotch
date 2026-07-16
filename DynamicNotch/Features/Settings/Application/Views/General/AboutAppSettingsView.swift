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
            contactMeCard
        }
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
                .frame(width: 90, height: 90)
                .scaleEffect(0.9)
                .background(LinearGradient.logoGradient.blur(radius: 20))
                .padding(.top, 20)
            
            VStack(spacing: 8) {
                Text("DynamicNotch")
                    .font(.system(size: 20, weight: .bold))
                
                Text("settings.about.description")
                    .font(.system(size: 14))
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
                cornerRadius: 30,
                position: .first,
                url: "https://t.me/Dynamic_Notch",
                onRequestInternetAccess: onRequestInternetAccess
            )
            
            SettingsUrlRowView(
                title: "GitHub Repository",
                description: "Star the project on GitHub",
                imageName: "gitHub",
                color: .clear,
                cornerRadius: 30,
                position: .middle,
                url: "https://github.com/jackson-storm/DynamicNotch",
                onRequestInternetAccess: onRequestInternetAccess
            )
            
            SettingsUrlRowView(
                title: "Website",
                description: "Open the DynamicNotch website",
                imageName: "simplifiedLogo",
                color: .clear,
                cornerRadius: 30,
                position: .last,
                url: "https://dynamicnotch.evgeniy-petrukovich.workers.dev",
                onRequestInternetAccess: onRequestInternetAccess
            )
        }
    }
    
    private var contactMeCard: some View {
        SettingsCard(title: "Contact Me", spacing: 0, padding: 0) {
            SettingsUrlRowView(
                title: "Telegram Account",
                description: "Send a direct message on Telegram",
                imageName: "telegram",
                color: .clear,
                cornerRadius: 30,
                position: .first,
                url: "https://t.me/id10101101",
                onRequestInternetAccess: onRequestInternetAccess
            )
            
            SettingsUrlRowView(
                title: "Email Address",
                description: "Send an email",
                imageName: "email",
                color: .clear,
                cornerRadius: 30,
                position: .last,
                url: "mailto:evgeniy.petrukovich@icloud.com?subject=A%20question%20about%20DynamicNotch",
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
