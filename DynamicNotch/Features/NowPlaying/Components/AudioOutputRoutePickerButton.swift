//
//  AudioOutputRoutePickerButton.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct AudioOutputRoutePickerButton: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    
    var width: CGFloat = 42
    var height: CGFloat = 42
    var fontSize: CGFloat = 20

    var body: some View {
        Menu {
            if nowPlayingViewModel.audioOutputRoutes.isEmpty {
                Text(verbatim: "No audio outputs available")
            } else {
                ForEach(nowPlayingViewModel.audioOutputRoutes) { route in
                    Button {
                        nowPlayingViewModel.switchAudioOutput(to: route)
                    } label: {
                        routeMenuLabel(route)
                    }
                }
            }
        } label: {
            Image(systemName: currentRouteSymbolName)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
        }
        .menuIndicator(.hidden)
        .buttonStyle(PressedButtonStyle(width: width, height: height))
        .onAppear {
            nowPlayingViewModel.refreshAudioOutputRoutes()
        }
    }

    private var currentRouteSymbolName: String {
        if let currentRoute = nowPlayingViewModel.currentAudioOutputRoute {
            return currentRoute.systemImageName
        }

        if let selectedRoute = nowPlayingViewModel.audioOutputRoutes.first(where: \.isCurrent) {
            return selectedRoute.systemImageName
        }

        return "airplayaudio"
    }

    private func routeMenuLabel(_ route: AudioOutputRoute) -> some View {
        HStack(spacing: 8) {
            Image(systemName: route.systemImageName)
                .frame(width: 18)

            Text(route.name)

            if route.isCurrent {
                Spacer(minLength: 12)
                Image(systemName: "checkmark")
            }
        }
    }
}
