internal import AppKit
import SwiftUI

@MainActor
struct NotificationsListView: View {
    let items: [AppNotificationItem]
    let onAudioPlaybackStateChanged: (Bool) -> Void
    let onOpenMessage: (MessagesMessage) -> Void
    let onOpenMail: (MailMessage) -> Void
    
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    
    init(
        items: [AppNotificationItem],
        onAudioPlaybackStateChanged: @escaping (Bool) -> Void = { _ in },
        onOpenMessage: @escaping (MessagesMessage) -> Void = { _ in },
        onOpenMail: @escaping (MailMessage) -> Void = { _ in }
    ) {
        self.items = items
        self.onAudioPlaybackStateChanged = onAudioPlaybackStateChanged
        self.onOpenMessage = onOpenMessage
        self.onOpenMail = onOpenMail
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            itemList
        }
        .padding(.leading, isDynamicIsland ? 12 : 45)
        .padding(.trailing, isDynamicIsland ? 20 : 45)
        .padding(.bottom, isDynamicIsland ? NotificationsNotchContent.dynamicIslandBottomPadding : NotificationsNotchContent.standardBottomPadding)
    }
    
    private var itemList: some View {
        VStack(spacing: NotificationsNotchContent.rowSpacing) {
            ForEach(items) { item in
                Group {
                    switch item {
                    case .message(let message):
                        MessagesNotificationRow(
                            message: message,
                            onAudioPlaybackStateChanged: onAudioPlaybackStateChanged,
                            onOpen: onOpenMessage
                        )
                    case .mail(let mail):
                        MailNotificationRow(
                            mail: mail,
                            onOpen: onOpenMail
                        )
                    }
                }
                .frame(height: items.count > 1 ? NotificationsNotchContent.rowHeight(for: item) : nil)
                .transition(itemTransition)
            }
        }
        .animation(.spring(response: 0.46, dampingFraction: 0.86, blendDuration: 0.12), value: items.map(\.id))
    }
    
    private var itemTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom)
                .combined(with: .blurAndFade)
                .combined(with: .scale(scale: 0.94, anchor: .bottom)),
            removal: .move(edge: .top)
                .combined(with: .blurAndFade)
                .combined(with: .scale(scale: 0.94, anchor: .top))
        )
    }
}
