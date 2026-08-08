import SwiftUI
internal import AppKit

struct TimerTextField: NSViewRepresentable {
    @Binding var value: String
    let maxValue: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value, maxValue: maxValue)
    }

    func makeNSView(context: Context) -> KeyableTimerTextField {
        let textField = KeyableTimerTextField()
        textField.delegate = context.coordinator
        textField.placeholderString = "00"
        textField.isBezeled = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.alignment = .center
        textField.textColor = .systemOrange
        textField.font = .systemFont(ofSize: 36, weight: .semibold)
        textField.maximumNumberOfLines = 1
        textField.stringValue = value
        return textField
    }

    func updateNSView(_ textField: KeyableTimerTextField, context: Context) {
        context.coordinator.value = $value
        context.coordinator.maxValue = maxValue
        if textField.stringValue != value {
            textField.stringValue = value
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var value: Binding<String>
        var maxValue: Int

        init(value: Binding<String>, maxValue: Int) {
            self.value = value
            self.maxValue = maxValue
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else { return }

            let digits = textField.stringValue.filter(\.isNumber)
            var sanitized = String(digits.prefix(2))
            if let number = Int(sanitized), number > maxValue {
                sanitized = String(maxValue)
            }

            if textField.stringValue != sanitized {
                textField.stringValue = sanitized
                textField.currentEditor()?.selectedRange = NSRange(location: sanitized.count, length: 0)
            }
            value.wrappedValue = sanitized
        }
    }
}

final class KeyableTimerTextField: NSTextField {
    override func mouseDown(with event: NSEvent) {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }
}
