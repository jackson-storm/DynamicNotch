import SwiftUI

struct SettingsSearchEmptyState: View {
    let query: String

    var body: some View {
        ContentUnavailableView(
            "No Settings Found",
            systemImage: "magnifyingglass",
            description: Text("Try a different keyword for \"\(query.trimmingCharacters(in: .whitespacesAndNewlines))\".")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SettingsPageScrollView<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                content
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 10)
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
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
        } label: {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
            }
            .padding(.bottom, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .groupBoxStyle(.automatic)
    }
}

struct SettingsSidebarRow: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            Text(title)
        } icon: {
            SettingsIconBadge(
                systemImage: systemImage,
                tint: tint,
                size: 22,
                iconSize: 12,
                cornerRadius: 6
            )
        }
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
        Toggle(isOn: $isOn) {
            HStack(alignment: .center, spacing: 12) {
                SettingsIconBadge(
                    systemImage: systemImage,
                    tint: color,
                    size: 30,
                    iconSize: 14,
                    cornerRadius: 9
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
        }
        .toggleStyle(CustomToggleStyle())
        .padding(10)
        .modifier(SettingsAccessibilityModifier(identifier: accessibilityIdentifier))
    }
}

private struct SettingsIconBadge: View {
    let systemImage: String
    let tint: Color
    let size: CGFloat
    let iconSize: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(tint.gradient)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
            }
    }
}

struct SettingsSliderRow: View {
    let title: String
    let description: String?
    let valueText: String
    let range: ClosedRange<Double>
    let step: Double
    let accessibilityIdentifier: String?

    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    if let description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                Text(valueText)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(value: $value, in: range, step: step)
        }
        .padding(10)
        .modifier(SettingsAccessibilityModifier(identifier: accessibilityIdentifier))
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
