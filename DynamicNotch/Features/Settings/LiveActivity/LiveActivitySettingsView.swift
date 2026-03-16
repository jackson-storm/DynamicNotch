import SwiftUI

struct LiveActivitySettingsView: View {
    @ObservedObject var viewModel: LiveActivitySettingsViewModel

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
        .accessibilityIdentifier("settings.activities.live.content")
    }
}
