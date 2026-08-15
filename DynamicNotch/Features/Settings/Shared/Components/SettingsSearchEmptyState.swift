import SwiftUI

struct SettingsSearchEmptyState: View {
    @Environment(\.locale) private var locale
    let query: String
    
    var body: some View {
        ContentUnavailableView(
            locale.dn("settings.search.empty.title", fallback: "No Settings Found"),
            systemImage: "magnifyingglass",
            description: Text(
                locale.dnFormat(
                    "settings.search.empty.subtitle",
                    fallback: "Try a different keyword for \"%@\".",
                    query.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
