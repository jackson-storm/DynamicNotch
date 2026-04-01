//
//  AboutApp.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/6/26.
//

import SwiftUI

struct AboutAppSettingsView: View {
    @Environment(\.openURL) private var openURL
    
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
        VStack(spacing: 0) {
            heroCard
            Divider()
            ScrollView(showsIndicators: false) {
                highlightsCard
                Spacer(minLength: 0)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .accessibilityIdentifier("settings.about.root")
    }
    
    private var heroCard: some View {
        ZStack {
            Rectangle()
                .fill(Gradient(colors: [Color.black.opacity(0.08), Color.accentColor.opacity(0.18), Color.black.opacity(0.08)]))
                .frame(height: 300)
            
            VStack(spacing: 15) {
                Image("logo")
                    .resizable()
                    .frame(width: 60, height: 60)
                
                VStack(alignment: .center, spacing: 3) {
                    Text("Dynamic Notch")
                        .font(.system(size: 18, weight: .semibold))
                        .accessibilityIdentifier("settings.about.title")
                    
                    Text("Make the cutout area more useful.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.accentColor.opacity(0.4))
                        .frame(width: 52, height: 20)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(Color.accentColor.opacity(0.6), lineWidth: 1)
                        }
                        .overlay {
                            Text(appVersionText)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.top, 4)
                }
                HStack(spacing: 14) {
                    Button(action: {
                        if let url = URL(string: "https://telegram.me/id10101101") {
                            openURL(url)
                        }
                    }) {
                        Image("telegram")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }
                    .accessibilityIdentifier("settings.about.telegram")
                    
                    Button(action: {
                        if let url = URL(string: "https://github.com/jackson-storm/DynamicNotch") {
                            openURL(url)
                        }
                    }) {
                        Image("gitHub")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }
                    .accessibilityIdentifier("settings.about.github")
                    
                    Button(action: {
                        let email = "evgeniy.petrukovich@icloud.com"
                        let subject = "A question about Dynamic Notch"
                        let body = ""
                        let urlString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                        if let url = URL(string: urlString) {
                            openURL(url)
                        }
                    }) {
                        Image("email")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }
                    .accessibilityIdentifier("settings.about.email")
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 50)
        }
    }
    
    private var highlightsCard: some View {
        VStack(spacing: 28) {
            AboutFeatureRow(
                image: "nowPlaying",
                title: "Live Activity",
                description: "Persistent notch content stays visible for as long as the source event is active, then fades away when it ends."
            )
            AboutFeatureRow(
                image: "fullPowerMode",
                title: "Temporary Activity",
                description: "Short-lived overlays appear above live activities so quick system events still feel prominent."
            )
            AboutFeatureRow(
                image: "lockScreen",
                title: "Lock Screen",
                description: "Carry notch context and media playback into the lock screen transition for a more cohesive experience."
            )
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .top)
    }
    
    private func open(_ value: String) {
        guard let url = URL(string: value) else { return }
        openURL(url)
    }
}

private struct AboutFeatureRow: View {
    let image: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            RoundedPreviewImage(
                image: image,
                width: 168,
                height: 82,
                cornerRadius: 14
            )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
    }
}

private struct RoundedPreviewImage: View {
    let image: String
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius + 1, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .frame(width: width + 2, height: height + 2)
            
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}
