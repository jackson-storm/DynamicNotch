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
