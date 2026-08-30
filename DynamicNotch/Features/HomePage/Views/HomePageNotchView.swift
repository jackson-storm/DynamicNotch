//
//  HomePageNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI

enum HomePages: String, CaseIterable, Hashable, Codable, Identifiable {
    case mediaPlayer
    case localTimer
    case camera
    case vpn
    case systemStats
    case fileConverter

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .mediaPlayer: return "Player"
        case .localTimer: return "Focus"
        case .camera: return "Camera"
        case .vpn: return "VPN"
        case .systemStats: return "Stats"
        case .fileConverter: return "Converter"
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .mediaPlayer: return "Control the current media session."
        case .localTimer: return "Start a simple focus timer."
        case .camera: return "Quickly access the camera."
        case .vpn: return "Manage VPN connections."
        case .systemStats: return "Monitor system resources."
        case .fileConverter: return "Convert files to multiple formats."
        }
    }

    var icon: String {
        switch self {
        case .mediaPlayer: return "play.fill"
        case .localTimer: return "timer"
        case .camera: return "camera.fill"
        case .vpn: return "network.badge.shield.half.filled"
        case .systemStats: return "cpu"
        case .fileConverter: return "arrow.trianglehead.2.clockwise.rotate.90"
        }
    }

    var tint: Color {
        switch self {
        case .mediaPlayer: return .purple
        case .localTimer: return .orange
        case .camera: return .gray
        case .vpn: return .blue
        case .systemStats: return .green
        case .fileConverter: return .blue
        }
    }

    var iconTint: Color {
        switch self {
        case .camera: return .black
        default: return .white
        }
    }
}

struct HomePageNotchView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let notchViewModel: NotchViewModel
    let settings: HomePageSettingsStore
    let localTimerViewModel: LocalTimerViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let clipboardHistoryViewModel: ClipboardHistoryViewModel
    let fileConverterViewModel: FileConverterViewModel
    let mediaAndFilesSettings: MediaAndFilesSettingsStore
    let applicationSettings: ApplicationSettingsStore
    let initialPage: HomePages

    @State private var currentPage: HomePages = .mediaPlayer
    @State private var isShowingClipboard = false

    private let primaryPages: [HomePages] = [.mediaPlayer, .localTimer]

    var body: some View {
        VStack(spacing: 12) {
            // Expanded content starts below the physical camera housing.
            Color.clear
                .frame(height: max(0, notchViewModel.notchModel.baseHeight))

            ZStack {
                Picker("Home", selection: $currentPage) {
                    ForEach(primaryPages) { page in
                        Text(page.title).tag(page)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .controlSize(isDynamicIsland ? .small : .large)
                .frame(width: isDynamicIsland ? 220 : 260)

                if mediaAndFilesSettings.isClipboardHistoryEnabled {
                    HStack {
                        Spacer()
                        ClipboardAccessButton(
                            viewModel: clipboardHistoryViewModel,
                            isPresented: $isShowingClipboard
                        )
                    }
                }
            }
            .frame(minHeight: 32)

            Group {
                if isShowingClipboard {
                    ClipboardHistoryNotchView(
                        viewModel: clipboardHistoryViewModel,
                        topClearance: 0,
                        appliesOuterPadding: false,
                        onItemRestored: { [weak notchViewModel] in
                            notchViewModel?.handleOutsideClick()
                        }
                    )
                } else {
                    switch currentPage {
                    case .mediaPlayer:
                        NowPlayingExpandedNotchView(
                            nowPlayingViewModel: nowPlayingViewModel,
                            settings: mediaAndFilesSettings,
                            applicationSettings: applicationSettings,
                            onOpenPlaybackSource: { [weak notchViewModel] in
                                notchViewModel?.handleOutsideClick()
                            },
                            isEmbeddedInHome: true
                        )
                    case .localTimer:
                        LocalTimerSetupNotchView(localTimerViewModel: localTimerViewModel)
                    default:
                        EmptyView()
                    }
                }
            }
            .id(isShowingClipboard ? "clipboard" : "page-\(currentPage.rawValue)")
            .transition(.opacity)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isShowingClipboard)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 36)
        .padding(.bottom, 28)
        .contentShape(Rectangle())
        .onAppear {
            currentPage = .mediaPlayer
            isShowingClipboard = false
        }
        .onChange(of: initialPage) { _, _ in
            currentPage = .mediaPlayer
            isShowingClipboard = false
        }
        .onChange(of: currentPage) {
            isShowingClipboard = false
        }
        .onChange(of: mediaAndFilesSettings.isClipboardHistoryEnabled) { _, isEnabled in
            if !isEnabled {
                isShowingClipboard = false
            }
        }
    }
}
