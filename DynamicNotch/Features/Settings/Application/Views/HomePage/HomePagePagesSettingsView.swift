import SwiftUI

struct HomePagePagesSettingsView: View {
    @ObservedObject var homePageSettings: HomePageSettingsStore

    var body: some View {
        SettingsPageScrollView {
            homePagePages
        }
    }

    private var homePagePages: some View {
        SettingsCard(title: "Pages") {
            SettingsOrderListView(
                items: $homePageSettings.homePageOrder,
                disabledItems: $homePageSettings.homePageDisabled,
                icon: { $0.icon },
                tint: { $0.tint },
                iconTint: { $0.iconTint },
                title: { $0.title },
                subtitle: { $0.subtitle },
                isListEnabled: homePageSettings.isHomePageLiveActivityEnabled
            )

            Divider().opacity(0.6)

            Text(LocalizedStringKey("Drag to reorder pages. Disabled pages will be hidden."))
                .font(.caption)
                .foregroundColor(.gray)
                .opacity(homePageSettings.isHomePageLiveActivityEnabled ? 1.0 : 0.5)
        }
    }
}
