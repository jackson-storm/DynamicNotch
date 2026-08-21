//
//  FavoriteTrackButton.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct FavoriteTrackButton: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel

    let width: CGFloat
    let height: CGFloat
    let fontSize: CGFloat

    var body: some View {
        Button {
            nowPlayingViewModel.toggleFavorite()
        } label: {
            Image(systemName: nowPlayingViewModel.isCurrentTrackFavorite ? "star.fill" : "star")
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(iconColor)
        }
        .buttonStyle(PressedButtonStyle(width: width, height: height))
        .disabled(!nowPlayingViewModel.canToggleFavorite)
        .opacity(nowPlayingViewModel.canToggleFavorite ? 1 : 0.45)
    }

    private var iconColor: Color {
        if nowPlayingViewModel.isCurrentTrackFavorite {
            return Color.white.opacity(0.5)
        }

        return .white.opacity(0.5)
    }
}
