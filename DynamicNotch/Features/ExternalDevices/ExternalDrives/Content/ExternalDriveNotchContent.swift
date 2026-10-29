import SwiftUI

struct ExternalDriveNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let drive: ExternalDriveModel
    let onOpen: @MainActor () -> Void
    let onEject: (@MainActor () -> Void)?

    var id: String { NotchContentRegistry.Notifications.externalDrive.id }
    var priority: Int { NotchContentRegistry.Notifications.externalDrive.priority }
    var windowLink: (@MainActor () -> Void)? { onOpen }

    func compactCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 20, bottom: 38)
    }

    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 120, height: baseHeight + 60)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 230, height: baseHeight + 60)
    }

    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.5
    }

    @MainActor
    func compactView() -> AnyView {
        AnyView(
            ExternalDriveNotificationView(drive: drive, onEject: onEject)
        )
    }
}
