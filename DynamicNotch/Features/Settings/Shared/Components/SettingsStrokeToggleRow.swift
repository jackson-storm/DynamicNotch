import SwiftUI

struct SettingsStrokeToggleRow: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let accessibilityIdentifier: String?

    @Binding var isOn: Bool

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil
    ) {
        self.title = title
        self.description = description
        self._isOn = isOn
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    var body: some View {
        SettingsToggleRow(
            title: title,
            description: description,
            systemImage: "inset.filled.capsule",
            color: .black,
            stroke: true,
            isOn: $isOn,
            accessibilityIdentifier: accessibilityIdentifier
        )
    }
}
