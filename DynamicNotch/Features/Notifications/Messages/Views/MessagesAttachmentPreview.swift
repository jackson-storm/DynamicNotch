internal import AppKit
import QuickLookThumbnailing
import SwiftUI

struct MessagesAttachmentPreview: View {
    let attachments: [MessagesAttachment]

    static let thumbnailSize: CGFloat = 33

    private let maximumVisibleAttachments = 3

    private var previewableAttachments: [MessagesAttachment] {
        attachments.filter { attachment in
            switch attachment {
            case .image, .video, .file:
                true
            case .audio:
                false
            }
        }
    }

    private var displayedAttachments: [MessagesAttachment] {
        Array(previewableAttachments.prefix(maximumVisibleAttachments))
    }

    private var remainingCount: Int {
        max(previewableAttachments.count - displayedAttachments.count, 0)
    }

    var body: some View {
        HStack(spacing: -6) {
            ForEach(displayedAttachments) { attachment in
                MessagesAttachmentThumbnail(attachment: attachment, size: Self.thumbnailSize)
            }

            if remainingCount > 0 {
                remainingAttachmentsView
            }
        }
    }

    private var remainingAttachmentsView: some View {
        Text(verbatim: "+\(remainingCount)")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(.black.opacity(0.45), lineWidth: 1)
            }
    }
}

private struct MessagesAttachmentThumbnail: View {
    let attachment: MessagesAttachment
    let size: CGFloat

    @State private var thumbnailImage: NSImage?

    private var fileURL: URL? {
        switch attachment {
        case .image(let attachment):
            attachment.fileURL
        case .video(let attachment):
            attachment.fileURL
        case .file(let attachment):
            attachment.fileURL
        case .audio:
            nil
        }
    }

    private var shouldLoadThumbnail: Bool {
        switch attachment {
        case .image, .video:
            true
        case .audio, .file:
            false
        }
    }

    private var isVideo: Bool {
        if case .video = attachment {
            return true
        }

        return false
    }

    private var fallbackImageName: String {
        switch attachment {
        case .image:
            "photo.fill"
        case .video:
            "film.fill"
        case .audio:
            "waveform"
        case .file:
            "doc.fill"
        }
    }

    private var fileIcon: NSImage? {
        guard case .file = attachment, let fileURL else { return nil }

        let icon = NSWorkspace.shared.icon(forFile: fileURL.path)
        icon.size = CGSize(width: size, height: size)

        return icon
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(.white.opacity(0.08))

            thumbnailContent

            if isVideo {
                videoIndicator
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(.black.opacity(0.45), lineWidth: 1)
        }
        .task(id: fileURL?.path) {
            thumbnailImage = nil
            loadThumbnailIfNeeded()
        }
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let thumbnailImage {
            Image(nsImage: thumbnailImage)
                .resizable()
                .scaledToFill()
        } else if let fileIcon {
            Image(nsImage: fileIcon)
                .resizable()
                .scaledToFit()
                .padding(4)
        } else {
            Image(systemName: fallbackImageName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var videoIndicator: some View {
        Circle()
            .fill(.black.opacity(0.58))
            .frame(width: 14, height: 14)
            .overlay {
                Image(systemName: "play.fill")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(x: 0.5)
            }
    }

    private func loadThumbnailIfNeeded() {
        guard shouldLoadThumbnail, thumbnailImage == nil, let fileURL else { return }

        let scale = NSScreen.main?.backingScaleFactor ?? 2
        let request = QLThumbnailGenerator.Request(
            fileAt: fileURL,
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
