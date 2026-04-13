import Foundation

extension SettingsRootViewModel {
    struct SelectionHistory {
        private(set) var entries: [Section]
        private(set) var currentIndex: Int

        init(initialSelection: Section) {
            self.entries = [initialSelection]
            self.currentIndex = 0
        }

        var currentSelection: Section {
            entries[currentIndex]
        }

        var canGoBack: Bool {
            currentIndex > 0
        }

        var canGoForward: Bool {
            currentIndex < entries.index(before: entries.endIndex)
        }

        mutating func record(_ selection: Section) {
            guard currentSelection != selection else { return }

            if canGoForward {
                entries.removeSubrange((currentIndex + 1)..<entries.endIndex)
            }

            entries.append(selection)
            currentIndex = entries.index(before: entries.endIndex)
        }

        mutating func goBack() -> Section? {
            guard canGoBack else { return nil }
            currentIndex -= 1
            return currentSelection
        }

        mutating func goForward() -> Section? {
            guard canGoForward else { return nil }
            currentIndex += 1
            return currentSelection
        }
    }
}
