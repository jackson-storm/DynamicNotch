//
//  AboutApp.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/6/26.
//

import SwiftUI

struct AboutAppSettingsView: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    private let heroCardHeight: CGFloat = 300
    
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
            Divider().opacity(0.6)
            
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
            AboutHeroBackground()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
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
        .frame(maxWidth: .infinity)
        .frame(height: heroCardHeight, alignment: .top)
        .clipped()
    }
    
    private var highlightsCard: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            AboutFeatureCard(
                title: "Live Activity",
                description: "Persistent notch content stays visible for as long as the source event is active, then fades away when it ends.",
                notchWidth: 168,
                notchHeight: 28,
                topCornerRadius: 5,
                bottomCornerRadius: 9,
                strokeColor: .indigo.opacity(0.3),
                applicationSettings: applicationSettings
            ) {
                AboutLiveActivityPreviewNotchView()
            }
            AboutFeatureCard(
                title: "Temporary Activity",
                description: "Short-lived overlays appear above live activities so quick system events still feel prominent.",
                notchWidth: 168,
                notchHeight: 28,
                topCornerRadius: 5,
                bottomCornerRadius: 9,
                strokeColor: .white.opacity(0.2),
                applicationSettings: applicationSettings
            ) {
                AboutTemporaryActivityPreviewNotchView()
            }
            AboutFeatureCard(
                title: "Lock Screen and Widget",
                description: "Carry notch context and media playback into the lock screen transition for a more cohesive experience.",
                notchWidth: 168,
                notchHeight: 28,
                topCornerRadius: 5,
                bottomCornerRadius: 9,
                strokeColor: .white.opacity(0.2),
                applicationSettings: applicationSettings
            ) {
                AboutLockScreenPreviewNotchView()
            }
            AboutFeatureCard(
                title: "Drag and Drop",
                description: "Drop files, images, or links onto the notch to trigger supported actions without breaking your flow.",
                notchWidth: 168,
                notchHeight: 80,
                topCornerRadius: 16,
                bottomCornerRadius: 24,
                strokeColor: .blue.opacity(0.3),
                applicationSettings: applicationSettings
            ) {
                AboutDragAndDropPreviewNotchView()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .top)
    }
    
    private func open(_ value: String) {
        guard let url = URL(string: value) else { return }
        openURL(url)
    }
}

private struct AboutHeroBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private var baseGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
            ? [
                Color(red: 0.03, green: 0.05, blue: 0.11),
                Color(red: 0.06, green: 0.16, blue: 0.21),
                Color(red: 0.03, green: 0.05, blue: 0.11)
            ]
            : [
                Color(red: 0.93, green: 0.97, blue: 1.00),
                Color(red: 0.86, green: 0.96, blue: 0.93),
                Color(red: 0.93, green: 0.97, blue: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(baseGradient)
                
                LinearGradient(
                    colors: [
                        Color.black.opacity(colorScheme == .dark ? 0.16 : 0.03),
                        .clear,
                        Color.black.opacity(colorScheme == .dark ? 0.28 : 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipShape(Rectangle())
        }
    }
}

private struct AboutFeatureCard: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let notchWidth: CGFloat
    let notchHeight: CGFloat
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat
    let strokeColor: Color
    let content: () -> AnyView
    
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        notchWidth: CGFloat,
        notchHeight: CGFloat,
        topCornerRadius: CGFloat,
        bottomCornerRadius: CGFloat,
        strokeColor: Color,
        applicationSettings: ApplicationSettingsStore,
        @ViewBuilder content: @escaping () -> some View
    ) {
        self.title = title
        self.description = description
        self.notchWidth = notchWidth
        self.notchHeight = notchHeight
        self.topCornerRadius = topCornerRadius
        self.bottomCornerRadius = bottomCornerRadius
        self.strokeColor = strokeColor
        self.applicationSettings = applicationSettings
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsNotchPreview(
                width: notchWidth,
                height: notchHeight,
                previewWidth: .infinity,
                previewHeight: 38,
                topCornerRadius: topCornerRadius,
                bottomCornerRadius: bottomCornerRadius,
                showsStroke: applicationSettings.isShowNotchStrokeEnabled,
                strokeColor: strokeColor,
                strokeWidth: 1,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) {
                content()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 156, alignment: .topLeading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        }
    }
}

private struct AboutLiveActivityPreviewNotchView: View {
    var body: some View {
        AboutMiniPreviewContainer {
            HStack(spacing: 0) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 11, weight: .bold))
                
                Spacer(minLength: 8)
                
                Text("On")
                    .font(.system(size: 11))
            }
            .foregroundStyle(.indigo)
            .padding(.horizontal, 12)
        }
    }
}

private struct AboutTemporaryActivityPreviewNotchView: View {
    private let level = 72
    private let indicatorWidth: CGFloat = 34
    
    private var activeLevelTint: Color {
        HudLevelStyling.fillTint(for: level, isEnabled: true)
    }
    
    private var filledIndicatorWidth: CGFloat {
        indicatorWidth * CGFloat(level) / 100
    }
    
    var body: some View {
        AboutMiniPreviewContainer {
            HStack(spacing: 6) {
                Image(systemName: HudPresentationKind.volume.symbolName(for: level))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: indicatorWidth, height: 4)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [activeLevelTint.opacity(0.82), activeLevelTint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: filledIndicatorWidth, height: 4)
                    }
            }
            .padding(.horizontal, 12)
        }
    }
}

private struct AboutLockScreenPreviewNotchView: View {
    var body: some View {
        AboutMiniPreviewContainer {
            HStack(spacing: 0) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
        }
    }
}

private struct AboutDragAndDropPreviewNotchView: View {
    var body: some View {
        AboutMiniPreviewContainer {
            VStack {
                Spacer()
                
                RoundedRectangle(cornerRadius: 14)
                    .fill(.blue.opacity(0.2))
                    .stroke(.blue, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round, dash: [15, 5]))
                    .frame(height: 60)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text(verbatim: "AirDrop")
                                .font(.system(size: 8))
                        }
                        .foregroundColor(.blue)
                    }
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 8)
        }
    }
}

private struct AboutMiniPreviewContainer<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
