import SwiftUI

struct SettingsToggleItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let systemImage: String
    let color: Color
    let accessibilityIdentifier: String
    let keyPath: ReferenceWritableKeyPath<GeneralSettingsViewModel, Bool>
}

struct SettingsToggleGroup: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let items: [SettingsToggleItem]
}

struct SettingsPageScrollView<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                content
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(.ultraThinMaterial)
    }
}

struct SettingsPageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 28, weight: .semibold))

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String?

    private let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

struct SettingsSidebarRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        } icon: {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 20)
        }
        .padding(.vertical, 4)
    }
}

struct SettingsToggleRow: View {
    let title: String
    let description: String
    let systemImage: String
    let color: Color
    let accessibilityIdentifier: String?

    @Binding var isOn: Bool

    init(
        title: String,
        description: String,
        systemImage: String,
        color: Color,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.color = color
        self._isOn = isOn
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    var body: some View {
        Group {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(color.gradient)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))

                    Text(description)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 16)

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .toggleStyle(CustomToggleStyle())
            }
        }
        .modifier(SettingsAccessibilityModifier(identifier: accessibilityIdentifier))
    }
}

struct SettingsToggleGroupCard: View {
    let group: SettingsToggleGroup
    let bindingProvider: (SettingsToggleItem) -> Binding<Bool>

    var body: some View {
        SettingsCard(
            title: group.title,
            subtitle: group.subtitle
        ) {
            VStack(spacing: 16) {
                ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                    SettingsToggleRow(
                        title: item.title,
                        description: item.description,
                        systemImage: item.systemImage,
                        color: item.color,
                        isOn: bindingProvider(item),
                        accessibilityIdentifier: item.accessibilityIdentifier
                    )

                    if index < group.items.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}

private struct SettingsAccessibilityModifier: ViewModifier {
    let identifier: String?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let identifier {
            content.accessibilityIdentifier(identifier)
        } else {
            content
        }
    }
}
