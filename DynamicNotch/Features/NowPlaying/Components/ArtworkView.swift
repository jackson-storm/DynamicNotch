//
//  ArtworkView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct ArtworkView: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    var body: some View {
        Group {
            if let artworkImage = nowPlayingViewModel.artworkImage {
                Image(nsImage: artworkImage)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
