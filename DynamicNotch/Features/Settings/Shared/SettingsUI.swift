import SwiftUI

struct SettingsSearchEmptyState: View {
    @Environment(\.locale) private var locale
    let query: String
    
    var body: some View {
        ContentUnavailableView(
            locale.dn("No Settings Found", fallback: "No Settings Found"),
            systemImage: "magnifyingglass",
            description: Text(
                locale.dnFormat(
                    "Try a different keyword for \"%@\".",
                    fallback: "Try a different keyword for \"%@\".",
                    query.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
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
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    
    private let content: Content
    
    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
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
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let systemImage: String
    let color: Color
    let accessibilityIdentifier: String?
    
    @Binding var isOn: Bool
    
    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
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
    let title: LocalizedStringKey
    let description: LocalizedStringKey?
    let range: ClosedRange<Double>
    let step: Double
    let fractionLength: Int
    let suffix: String?
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
                
                AnimatedLevelText(
                    value: value,
                    fontSize: 12,
                    fractionLength: fractionLength,
                    suffix: suffix,
                    color: .secondary
                )
            }
            
            Slider(value: $value, in: range, step: step)
        }
        .padding(10)
        .modifier(SettingsAccessibilityModifier(identifier: accessibilityIdentifier))
    }
}

struct NotchPreview<Overlay: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let width: CGFloat
    let height: CGFloat
    let previewHeight: CGFloat
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat
    let showsStroke: Bool
    let strokeColor: Color
    let strokeWidth: CGFloat

    private let overlay: Overlay

    init(
        width: CGFloat = 370,
        height: CGFloat = 38,
        previewHeight: CGFloat = 138,
        topCornerRadius: CGFloat = 9,
        bottomCornerRadius: CGFloat = 13,
        showsStroke: Bool = true,
        strokeColor: Color = .green.opacity(0.3),
        strokeWidth: CGFloat = 1.5,
        @ViewBuilder overlay: () -> Overlay
    ) {
        self.width = width
        self.height = height
        self.previewHeight = previewHeight
        self.topCornerRadius = topCornerRadius
        self.bottomCornerRadius = bottomCornerRadius
        self.showsStroke = showsStroke
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.overlay = overlay()
    }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.08) : Color.gray.opacity(0.18))
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                .frame(height: previewHeight)

            NotchShape(
                topCornerRadius: topCornerRadius,
                bottomCornerRadius: bottomCornerRadius
            )
            .fill(.black)
            .overlay {
                NotchShape(
                    topCornerRadius: topCornerRadius,
                    bottomCornerRadius: bottomCornerRadius
                )
                .stroke(
                    showsStroke ? strokeColor : .clear,
                    lineWidth: strokeWidth
                )
            }
            .overlay {
                overlay
            }
            .frame(width: width, height: height)
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
