import SwiftUI

struct CalculatorNotchView: View {
    @ObservedObject var model: MiniCalculatorModel
    let isActive: Bool
    @Environment(\.locale) private var locale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @FocusState private var hasKeyboardFocus: Bool

    private struct KeyRow: Identifiable {
        let id: String
        let keys: [MiniCalculatorEngine.Key]
    }

    private let rows: [KeyRow] = [
        .init(id: "functions", keys: [.clear, .changeSign, .percent, .operation(.divide)]),
        .init(id: "upper", keys: [.digit(7), .digit(8), .digit(9), .operation(.multiply)]),
        .init(id: "middle", keys: [.digit(4), .digit(5), .digit(6), .operation(.subtract)]),
        .init(id: "lower", keys: [.digit(1), .digit(2), .digit(3), .operation(.add)])
    ]

    var body: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: 12) {
                Button { model.copyResult(locale: locale) } label: {
                    Image(systemName: model.didCopy ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(model.didCopy ? Color.green : Color.white.opacity(0.6))
                        .frame(width: 30, height: 34)
                }
                .buttonStyle(.plain)
                .disabled(model.engine.hasError)
                .help("homeTools.calculator.copy")
                .accessibilityLabel(Text("homeTools.calculator.copy"))
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(model.engine.expression(locale: locale))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                        .frame(height: 13)
                    Text(model.engine.hasError ? locale.dn("homeTools.calculator.error") : model.engine.display(locale: locale))
                        .font(.system(size: 32, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.45)
                        .accessibilityIdentifier("homeTools.calculator.result")
                }
            }
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                ForEach(rows) { row in
                    GridRow {
                        ForEach(row.keys, id: \.self) { key in keyButton(key) }
                    }
                }
                GridRow {
                    keyButton(.digit(0)).gridCellColumns(2)
                    keyButton(.decimal)
                    keyButton(.equals)
                }
            }
        }
        .padding(.horizontal, isNotchlessScreen ? 18 : 36)
        .padding(.bottom, 16)
        .focusable(isActive)
        .focused($hasKeyboardFocus)
        .focusEffectDisabled()
        .onKeyPress { press in handleKey(press) }
        .task(id: isActive) {
            await Task.yield()
            guard !Task.isCancelled else { return }
            hasKeyboardFocus = isActive
        }
    }

    private func keyButton(_ key: MiniCalculatorEngine.Key) -> some View {
        let isOperation: Bool
        let isSelected: Bool
        switch key {
        case .operation(let operation): isOperation = true; isSelected = model.engine.selectedOperation == operation
        case .equals: isOperation = true; isSelected = false
        default: isOperation = false; isSelected = false
        }
        let isFunction: Bool
        switch key {
        case .clear, .changeSign, .percent: isFunction = true
        default: isFunction = false
        }
        return Button { model.press(key) } label: {
            Text(verbatim: title(for: key))
                .font(.system(size: isOperation ? 22 : 18, weight: .medium))
                .foregroundStyle(isSelected ? Color.orange : Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .contentShape(RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(CalculatorKeyStyle(color: isSelected ? .white : isOperation ? .orange : .white.opacity(isFunction ? 0.25 : 0.12)))
        .accessibilityLabel(accessibilityTitle(for: key))
    }

    private func title(for key: MiniCalculatorEngine.Key) -> String {
        switch key {
        case .digit(let value): return String(value)
        case .decimal: return locale.decimalSeparator ?? "."
        case .operation(let operation): return operation.rawValue
        case .clear: return model.engine.clearTitle
        case .changeSign: return "±"
        case .percent: return "%"
        case .equals: return "="
        case .backspace: return "⌫"
        }
    }

    private func accessibilityTitle(for key: MiniCalculatorEngine.Key) -> Text {
        switch key {
        case .clear: return Text("homeTools.calculator.clear")
        case .changeSign: return Text("homeTools.calculator.sign")
        case .percent: return Text("homeTools.calculator.percent")
        case .equals: return Text("homeTools.calculator.equals")
        default: return Text(verbatim: title(for: key))
        }
    }

    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        guard isActive else { return .ignored }
        if press.modifiers.contains(.command) {
            guard press.characters.lowercased() == "c" else { return .ignored }
            model.copyResult(locale: locale)
            return .handled
        }
        let key: MiniCalculatorEngine.Key
        if press.key == .return { key = .equals }
        else if press.key == .delete { key = .backspace }
        else if press.key == .escape { key = .clear }
        else {
            switch press.characters {
            case "0"..."9":
                guard let digit = Int(press.characters) else { return .ignored }
                key = .digit(digit)
            case ".", ",": key = .decimal
            case "+": key = .operation(.add)
            case "-", "−": key = .operation(.subtract)
            case "*", "×": key = .operation(.multiply)
            case "/", "÷": key = .operation(.divide)
            case "%": key = .percent
            case "=": key = .equals
            default: return .ignored
            }
        }
        model.press(key)
        return .handled
    }
}

private struct CalculatorKeyStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(color.opacity(configuration.isPressed ? 0.65 : 1), in: RoundedRectangle(cornerRadius: 17))
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
