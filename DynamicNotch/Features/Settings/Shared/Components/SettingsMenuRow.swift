import SwiftUI

struct SettingsMenuRow<Option: Hashable>: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let options: [Option]
    let optionTitle: (Option) -> LocalizedStringKey
    let accessibilityIdentifier: String?

    @Binding var selection: Option

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        HStack {
                            Text(optionTitle(option))
                            if option == selection {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Text(optionTitle(selection))
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .modifier(SettingsAccessibilityModifier(identifier: accessibilityIdentifier))
    }
}
