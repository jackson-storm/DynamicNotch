import SwiftUI

struct TemporaryActivitySettingsView: View {
    @ObservedObject var viewModel: TemporaryActivitySettingsViewModel

    var body: some View {
        SettingsPageScrollView {
            ForEach(viewModel.groups) { group in
                SettingsToggleGroupCard(
                    group: group,
                    bindingProvider: viewModel.binding(for:)
                )
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("settings.activities.temporary.content")
    }
}
