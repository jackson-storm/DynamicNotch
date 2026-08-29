import SwiftUI

struct ExternalDriveNotificationView: View {
    let drive: ExternalDriveModel
    let onEject: (@MainActor () -> Void)?

    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @State private var isEjectHovered = false

    var body: some View {
        VStack {
            Spacer()
            content
        }
        .padding(.leading, isDynamicIsland ? 19 : 40)
        .padding(.trailing, isDynamicIsland ? 15 : 35)
        .padding(.bottom, isDynamicIsland ? 19 : 15)
    }

    private var content: some View {
        HStack(alignment: .center, spacing: 12) {
            driveIcon
            
            VStack(alignment: .leading, spacing: 3) {
                Text(drive.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                subtitleView
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if drive.eventType == .connected && drive.isEjectable, let onEject {
                ejectButton(action: onEject)
            }
        }
        .id(drive.id + "-\(drive.eventType)")
        .transition(.blurAndFade.combined(with: .opacity).animation(.spring(response: 0.6)))
    }

    @ViewBuilder
    private var driveIcon: some View {
        if let icon = drive.icon {
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 45, height: 45)
            
        } else {
            Image(systemName: drive.isDiskImage ? "opticaldiscdrive.fill" : "externaldrive.fill")
                .font(.system(size: 26))
                .foregroundStyle(.white)
                .frame(width: 45, height: 45)
        }
    }

    @ViewBuilder
    private var subtitleView: some View {
        if drive.eventType == .connected {
            if let capacity = drive.formattedCapacity {
                Text(capacity)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
            } else if drive.isDiskImage {
                Text("settings.notifications.externalDrives.diskImage")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        } else {
            Text("settings.notifications.externalDrives.safeToDisconnect")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func ejectButton(action: @escaping @MainActor () -> Void) -> some View {
        Button { action() } label: {
            Image(systemName: "eject.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .gray.opacity(0.3)))
    }
}
