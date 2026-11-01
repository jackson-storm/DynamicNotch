internal import AppKit
import Combine

@MainActor
final class MiniCalculatorModel: ObservableObject {
    @Published private(set) var engine = MiniCalculatorEngine()
    @Published private(set) var didCopy = false

    func press(_ key: MiniCalculatorEngine.Key) {
        didCopy = false
        engine.press(key)
    }

    func copyResult(locale: Locale) {
        guard !engine.hasError else { return }
        let text = engine.display(locale: locale)
        NSPasteboard.general.clearContents()
        didCopy = NSPasteboard.general.setString(text, forType: .string)
    }
}
