import SwiftUI

struct ExternalDriveNotificationView: View {
    let drive: ExternalDriveModel
    let onEject: (@MainActor () -> Void)?

    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @Environment(\.locale) private var locale
    @State private var isEjectHovered = false

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                driveIcon
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(drive.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    subtitleView
                }
                
                Spacer()
                
                if drive.eventType == .connected && drive.isEjectable, let onEject {
                    ejectButton(action: onEject)
                }
            }
            .id(drive.id + "-\(drive.eventType)")
            .transition(.blurAndFade.combined(with: .opacity).animation(.spring(response: 0.6)))
        }
        .padding(.top, isNotchlessScreen ? 0 : 20)
        .padding(.leading, isNotchlessScreen ? 20 : 40)
        .padding(.trailing, isNotchlessScreen ? 15 : 33)
    }

    @ViewBuilder
    private var driveIcon: some View {
        if let icon = drive.icon {
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 45, height: 45)
            
        } else {
            Image(systemName: "externaldrive.fill")
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
            }
        } else {
            Text(locale.dn("notch.externalDrive.safeToDisconnect", fallback: "Safe to disconnect"))
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
        .buttonStyle(PrimaryButtonStyle(width: 50, height: 50, backgroundColor: .gray.opacity(0.3)))
    }
}
