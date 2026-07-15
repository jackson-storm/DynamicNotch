//
//  SupportSettingsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/14/26.
//

import SwiftUI

struct SupportSettingsView: View {
    let onRequestInternetAccess: () -> Bool
    
    @Environment(\.openURL) private var openURL
    @State private var imageAppear = false
    
    var body: some View {
        SettingsPageScrollView {
            headerCard
            supportCard
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                imageAppear = true
            }
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            AnimateImage(name: "money")
                .frame(width: 100, height: 100)
                .scaleEffect(1.1)
                .shadow(color: .yellow, radius: 30)
                .id(imageAppear)
                .padding(.top, 20)
            
            VStack(spacing: 8) {
                Text("settings.support.title")
                    .font(.system(size: 20, weight: .bold))
                
                Text("settings.support.description")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
            }
        }
    }
    
    private var supportCard: some View {
        SettingsCard(spacing: 0, padding: 0) {
            SettingsUrlRowView(
                title: "Buy Me a Coffee",
                description: "Support with a one-time coffee donation.",
                systemImage: "cup.and.saucer.fill",
                color: .orange,
                position: .first,
                url: "https://buymeacoffee.com",
                onRequestInternetAccess: onRequestInternetAccess
            )
            
            SettingsUrlRowView(
                title: "Patreon",
                description: "Become a monthly sponsor and get exclusive updates.",
                systemImage: "person.2.fill",
                color: .red,
                position: .middle,
                url: "https://patreon.com",
                onRequestInternetAccess: onRequestInternetAccess
            )
            
            SettingsUrlRowView(
                title: "PayPal",
                description: "Quick and secure one-time donations.",
                systemImage: "creditcard.fill",
                color: .blue,
                position: .last,
                url: "https://paypal.me",
                onRequestInternetAccess: onRequestInternetAccess
            )
        }
    }
}
