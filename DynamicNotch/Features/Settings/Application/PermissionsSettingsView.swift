import SwiftUI

struct PermissionsSettingsView: View {
    @ObservedObject var permissionController: SettingsPermissionController
    @ObservedObject var applicationSettings: ApplicationSettingsStore

    private func localized(_ key: String, fallback: String) -> String {
        applicationSettings.appLanguage.locale.dn(key, fallback: fallback)
    }

    var body: some View {
        SettingsPageScrollView {
            permissionsCard
        }
        .onAppear {
            permissionController.refresh()
        }
    }

    private var permissionsCard: some View {
        SettingsCard(title: "settings.permissions.card.title") {
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
