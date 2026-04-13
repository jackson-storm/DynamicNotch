//
//  DownloadFileThumbnailView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI
import QuickLookThumbnailing

struct DownloadFileThumbnailView: View {
    let url: URL
    let size: CGFloat
    
    @State private var thumbnailImage: NSImage?

    private var fallbackIcon: NSImage {
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = CGSize(width: size, height: size)
        return icon
    }

    var body: some View {
        Group {
            if let thumbnailImage {
                Image(nsImage: thumbnailImage)
                    .resizable()
            } else {
                Image(nsImage: fallbackIcon)
                    .resizable()
            }
        }
        .frame(width: size, height: size)
        .task(id: url.path) {
            loadThumbnailIfNeeded()
        }
    }

    private func loadThumbnailIfNeeded() {
        guard thumbnailImage == nil else { return }

        let scale = NSScreen.main?.backingScaleFactor ?? 2
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: size, height: size),
            scale: scale,
            representationTypes: .thumbnail
        )

        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, _ in
            guard let representation else { return }

            DispatchQueue.main.async {
                thumbnailImage = representation.nsImage
            }
        }
    }
}
