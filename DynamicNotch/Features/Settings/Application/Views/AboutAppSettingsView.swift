//
//  AboutApp.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/6/26.
//

import SwiftUI

enum AboutAppTab: String, CaseIterable, Identifiable {
    case about
    case support
    
    var id: String { rawValue }
    
    var titleKey: LocalizedStringKey {
        switch self {
        case .about:
            return "settings.section.about.title"
        case .support:
            return "settings.general.support.title"
        }
    }
}

struct AboutAppSettingsView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    @ObservedObject private var updater = SparkleUpdater.shared
    
    let onRequestInternetAccess: () -> Bool
    
    @State private var selectedTab: AboutAppTab = .about
    
    private var currentVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return "\(version)"
    }
    
    private var appVersionText: String {
        "v\(currentVersion)"
    }
    
    var body: some View {
        Group {
            switch selectedTab {
            case .about:
                aboutTab
            case .support:
                SupportSettingsView(onRequestInternetAccess: onRequestInternetAccess)
            }
        }
        .accessibilityIdentifier("settings.about.root")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Picker("", selection: $selectedTab.animation(.easeInOut(duration: 0.2))) {
                    ForEach(AboutAppTab.allCases) { tab in
                        Text(tab.titleKey).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            ToolbarItem(placement: .primaryAction) {
                Text(appVersionText)
                    .padding(.horizontal, 10)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SelectSettingsSubPage"))) { notification in
            if let subPage = notification.object as? SettingsSubPage {
                if subPage == .support {
                    selectedTab = .support
                } else if subPage == .about || subPage == .softwareUpdate {
                    selectedTab = .about
                }
            }
        }
    }
    
    private var aboutTab: some View {
        SettingsPageScrollView {
            headerCard
            softwareUpdateCard
            socialLinksCard
            contactMeCard
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            Image("logo")
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFill()
                .frame(width: 90, height: 90)
                .cornerRadius(20)
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
    
    private var softwareUpdateCard: some View {
        SettingsCard {
            SettingsButtonRow(
                title: "settings.section.softwareUpdate.title",
                description: "Version \(currentVersion)",
                buttonTitle: "settings.update.checkNow",
                isButtonDisabled: !updater.canCheckForUpdates,
                accessibilityIdentifier: "settings.update.versionCard"
            ) {
                updater.checkForUpdates()
            }
            
            Divider()
                .opacity(0.6)
            
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
    
    private var socialLinksCard: some View {
        SettingsCard(title: "settings.about.card.socialLinks", spacing: 0, padding: 0) {
            SettingsUrlRowView(
                title: "settings.about.telegramChannel.title",
                description: "settings.about.telegramChannel.desc",
                imageName: "telegram",
                color: .clear,
                cornerRadius: 30,
                position: .first,
                url: "https://t.me/Dynamic_Notch",
                onRequestInternetAccess: onRequestInternetAccess
            )
            
            SettingsUrlRowView(
                title: "settings.about.github.title",
                description: "settings.about.github.desc",
                imageName: "gitHub",
                color: .clear,
                cornerRadius: 30,
                position: .middle,
                url: "https://github.com/jackson-storm/DynamicNotch",
                onRequestInternetAccess: onRequestInternetAccess
            )
            
            SettingsUrlRowView(
                title: "settings.about.website.title",
                description: "settings.about.website.desc",
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
        SettingsCard(title: "settings.about.card.contact", spacing: 0, padding: 0) {
            SettingsUrlRowView(
                title: "settings.about.telegramAccount.title",
                description: "settings.about.telegramAccount.desc",
                imageName: "telegram",
                color: .clear,
                cornerRadius: 30,
                position: .first,
                url: "https://t.me/id10101101",
                onRequestInternetAccess: onRequestInternetAccess
            )
            
            SettingsUrlRowView(
                title: "settings.about.email.title",
                description: "settings.about.email.desc",
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
