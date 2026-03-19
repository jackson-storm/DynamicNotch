//
//  AboutApp.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/6/26.
//

import SwiftUI

struct AboutAppSettingsView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            logoAndDescription
            Divider().opacity(0.8)
            aboutAppDescription
            Spacer()
        }
        .accessibilityIdentifier("settings.about.root")
    }
    
    @ViewBuilder
    var logoAndDescription: some View {
        ZStack {
            Rectangle()
                .fill(.tint)
                .frame(width: 250, height: 40)
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: 240)
            
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
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.orange.opacity(0.4))
                        .stroke(.orange.opacity(0.6), lineWidth: 1)
                        .frame(width: 45, height: 18)
                        .overlay(
                            Text("v.1.0.0")
                                .font(.system(size: 11))
                        )
                        .padding(3)
                }
                HStack {
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
            .padding(20)
        }
    }
    
    @ViewBuilder
    var aboutAppDescription: some View {
        VStack(spacing: 20) {
            TextWithImage(
                image: "focusMode",
                title: "Live Activity",
                description: "The notch is active as long as the event is active, as soon as the event disappears the content disappears."
            )
            TextWithImage(
                image: "fullPowerMode",
                title: "Temporary Activity",
                description: "When an event is triggered, a temporary activity is shown that overlays the live activity."
            )
            TextWithImage(
                image: "fullPowerMode",
                title: "Lock screen",
                description: "Display the notch and active player on the lock screen."
            )
        }
        .padding(20)
    }
}

private struct TextWithImage: View {
    var image: String
    var title: String
    var description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            RoundedImage(image: image, width: 180, height: 80, cornerRadius: 12)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
        }
    }
}

private struct RoundedImage: View {
    var image: String
    var width: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius + 1)
                .stroke(.gray.opacity(0.3), lineWidth: 2)
                .frame(width: width + 2, height: height + 2)
            
            Image(image)
                .resizable()
                .frame(width: width, height: height)
                .cornerRadius(cornerRadius)
        }
    }
}
