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
            supportServicesCard
            cryptoDonationCard
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
                .frame(width: 90, height: 90)
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
    
    private var supportServicesCard: some View {
        SettingsCard(title: "Services", spacing: 0, padding: 0) {
            SettingsUrlRowView(
                title: "Boosty.to",
                description: "Support development or subscribe",
                imageName: "boosty",
                imageSize: 16,
                color: .white,
                stroke: true,
                position: .first,
                url: "https://boosty.to/jacksonstormdev",
                onRequestInternetAccess: onRequestInternetAccess
            )
            
            SettingsUrlRowView(
                title: "Donation Alerts",
                description: "One-time donation via cards or crypto",
                imageName: "donationAlerts",
                imageSize: 16,
                color: .orange,
                position: .last,
                url: "https://www.donationalerts.com/r/jacksonstormdev",
                onRequestInternetAccess: onRequestInternetAccess
            )
        }
    }
    
    private var cryptoDonationCard: some View {
        SettingsCard(title: "Cryptocurrency", spacing: 0, padding: 0) {
            SettingsCopyRowView(
                title: "USDT (TRC-20)",
                description: "Address: \("TWYo42HQNuXSA5gmVoVV1973ScPqCtduvA")",
                imageName: "trc-20",
                color: .clear,
                position: .first,
                textToCopy: "TWYo42HQNuXSA5gmVoVV1973ScPqCtduvA"
            )
            
            SettingsCopyRowView(
                title: "USDT (ERC-20)",
                description: "Address: \("0xd3261630d7EC2484A3fcf5315f194B58834ab891")",
                imageName: "erc-20",
                color: .clear,
                stroke: true,
                position: .middle,
                textToCopy: "0xd3261630d7EC2484A3fcf5315f194B58834ab891"
            )
            
            SettingsCopyRowView(
                title: "Bitcoin (BTC)",
                description: "Address: \("bc1qw29074zwlp600rhvjat2v7ks53h835tthfj7dx")",
                imageName: "btc",
                color: .clear,
                position: .last,
                textToCopy: "bc1qw29074zwlp600rhvjat2v7ks53h835tthfj7dx"
            )
        }
    }
}
