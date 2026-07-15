import SwiftUI

struct PermissionsSettingsView: View {
    @ObservedObject var permissionController: SettingsPermissionController
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    @State private var imageAppear = false

    private func localized(_ key: String, fallback: String) -> String {
        applicationSettings.appLanguage.locale.dn(key, fallback: fallback)
    }

    var body: some View {
        SettingsPageScrollView {
            headerCard
            permissionsCard
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                imageAppear = true
            }
            permissionController.refresh()
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            AnimateImage(name: "confirm")
                .frame(width: 90, height: 90)
                .scaleEffect(1.5)
                .shadow(color: .green, radius: 30)
                .id(imageAppear)
                .padding(.top, 20)
            
            VStack(spacing: 8) {
                Text("settings.permissions.page.title")
                    .font(.system(size: 20, weight: .bold))
                
                Text("settings.permissions.page.subtitle")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
            }
        }
    }

    private var permissionsCard: some View {
        SettingsCard() {
            ForEach(Array(permissionController.permissionItems.enumerated()), id: \.element.id) { index, item in
                permissionRow(for: item)

                if index < permissionController.permissionItems.count - 1 {
                    Divider()
                        .opacity(0.6)
                        .padding(.leading, 43)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                }
            }
        }
    }

    @ViewBuilder
    private func permissionRow(for item: PermissionItem) -> some View {
        HStack(alignment: .center, spacing: 12) {
            if let assetImageName = item.assetImageName {
                SettingsIconBadge(
                    imageName: assetImageName,
                    tint: item.tintColor,
                    size: 30,
                    iconSize: 14,
                    cornerRadius: 9
                )
            } else {
                SettingsIconBadge(
                    systemImage: item.systemImage,
                    tint: item.tintColor,
                    size: 30,
                    iconSize: 14,
                    cornerRadius: 9
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    Text(localized(item.titleKey, fallback: item.fallbackTitle))

                    HStack(spacing: 5) {
                        Image(systemName: item.isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(
                            localized(
                                item.isGranted ?
                                "settings.permissions.status.granted" :
                                "settings.permissions.status.needsAccess",
                                fallback: item.isGranted ? "Granted" : "Needs access"
                            )
                        )
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(item.isGranted ? .green : .orange)
                }

                Text(localized(item.descriptionKey, fallback: item.fallbackDescription))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            if let actionTitleKey = item.actionTitleKey,
               let fallbackActionTitle = item.fallbackActionTitle {
                Button(localized(actionTitleKey, fallback: fallbackActionTitle)) {
                    permissionController.performAction(for: item.kind)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityIdentifier("\(item.accessibilityIdentifier).action")
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
            }
        }
        .modifier(SettingsAccessibilityModifier(identifier: item.accessibilityIdentifier))
    }
}
