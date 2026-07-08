import SwiftUI

struct HomePageSettingsView: View {
    @ObservedObject var homePageSettings: HomePageSettingsStore

    var body: some View {
        SettingsPageScrollView {
            homePageCard
        }
    }

    private var homePageCard: some View {
        SettingsCard(title: "Home Page") {
            SettingsToggleRow(
                title: "Home Page live activity",
                description: "Show the Home Page in the notch.",
                systemImage: "house.fill",
                color: .blue,
                isOn: $homePageSettings.isHomePageLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.homePage"
            )

            Divider().opacity(0.6)
            
            SettingsToggleRow(
                title: "settings.homePage.pageIndicator.title",
                description: "settings.homePage.pageIndicator.description",
                systemImage: "ellipsis.circle",
                color: .purple,
                isOn: $homePageSettings.isHomePagePageIndicatorEnabled,
                accessibilityIdentifier: "settings.homePage.pageIndicator"
            )

            Divider().opacity(0.6)
            
            SettingsMenuRow(
                title: "settings.homePage.indicatorSize.title",
                description: "settings.homePage.indicatorSize.description",
                options: Array(HomePageIndicatorSize.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.homePage.indicatorSize",
                selection: $homePageSettings.homePageIndicatorSize
            )
            .disabled(!homePageSettings.isHomePagePageIndicatorEnabled)
            .opacity(homePageSettings.isHomePagePageIndicatorEnabled ? 1.0 : 0.5)

            Divider().opacity(0.6)

            List {
                ForEach(homePageSettings.homePageOrder, id: \.self) { page in
                    HStack(spacing: 12) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.gray.opacity(0.5))
                            .font(.system(size: 14))

                        SettingsIconBadge(
                            systemImage: page.icon,
                            tint: page.tint,
                            size: 30,
                            iconSize: 14,
                            cornerRadius: 9
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(page.title)
                            Text(page.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { !homePageSettings.homePageDisabled.contains(page) },
                            set: { isEnabled in
                                if isEnabled {
                                    homePageSettings.homePageDisabled.remove(page)
                                } else {
                                    homePageSettings.homePageDisabled.insert(page)
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(.gray.opacity(0.15))
                }
                .onMove { from, to in
                    homePageSettings.homePageOrder.move(fromOffsets: from, toOffset: to)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .frame(height: CGFloat(homePageSettings.homePageOrder.count) * 52)
            .disabled(!homePageSettings.isHomePageLiveActivityEnabled)
            .opacity(homePageSettings.isHomePageLiveActivityEnabled ? 1.0 : 0.5)

            Divider().opacity(0.6)

            Text(LocalizedStringKey("Drag to reorder pages. Disabled pages will be hidden."))
                .font(.caption)
                .foregroundColor(.gray)
                .opacity(homePageSettings.isHomePageLiveActivityEnabled ? 1.0 : 0.5)
        }
    }
}
