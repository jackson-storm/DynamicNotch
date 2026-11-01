import Foundation

struct MiniCalculatorEngine {
    enum Operation: String {
        case add = "+", subtract = "−", multiply = "×", divide = "÷"
    }

    enum Key: Hashable {
        case digit(Int), decimal, operation(Operation), equals, percent, changeSign, clear, backspace
    }

    private enum Token {
        case number(Decimal), operation(Operation)
    }

    private enum CalculationError: Error { case divisionByZero, overflow, invalidExpression }

    private var entry = "0"
    private var tokens: [Token] = []
    private var completedExpression: [Token] = []
    private var isEntering = true
    private var justEvaluated = false
    private var repeatedOperation: Operation?
    private var repeatedOperand: Decimal?
    private(set) var hasError = false

    private var entryValue: Decimal {
        Decimal(string: entry, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }

    var value: Decimal? {
        guard !hasError else { return nil }
        if !isEntering, !tokens.isEmpty {
            return try? Self.evaluate(Array(tokens.dropLast()))
        }
        return entryValue
    }

    var clearTitle: String { entry == "0" && !hasError ? "AC" : "C" }

    var selectedOperation: Operation? {
        guard !isEntering, case .operation(let operation) = tokens.last else { return nil }
        return operation
    }

    func display(locale: Locale) -> String {
        guard !hasError else { return "Error" }
        if isEntering && !justEvaluated {
            return entry.replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".")
        }
        return Self.format(value ?? 0, locale: locale)
    }

    func expression(locale: Locale) -> String {
        var expression = justEvaluated ? completedExpression : tokens
        if isEntering && !justEvaluated && !tokens.isEmpty { expression.append(.number(entryValue)) }
        return expression.map { token in
            switch token {
            case .number(let number): return Self.format(number, locale: locale)
            case .operation(let operation): return operation.rawValue
            }
        }.joined(separator: " ")
    }

    mutating func press(_ key: Key) {
        switch key {
        case .clear:
            if entry == "0" && !hasError { self = Self() }
            else {
                if justEvaluated || hasError { tokens = [] }
                entry = "0"; isEntering = true; justEvaluated = false; hasError = false
            }
        case .digit(let digit):
            guard (0...9).contains(digit) else { return }
            prepareEntry()
            guard entry.filter(\.isNumber).count < 16 else { return }
            if entry == "0" { entry = String(digit) }
            else if entry == "-0" { entry = "-\(digit)" }
            else { entry += String(digit) }
        case .decimal:
            prepareEntry()
            if !entry.contains(".") { entry += "." }
        case .changeSign:
            if hasError { self = Self() }
            if justEvaluated { tokens = []; justEvaluated = false }
            if !isEntering { entry = "0"; isEntering = true }
            entry = entry.hasPrefix("-") ? String(entry.dropFirst()) : "-" + entry
        case .backspace:
            if hasError || justEvaluated { self = Self(); return }
            if !isEntering {
                if !tokens.isEmpty { tokens.removeLast() }
                if case .number(let number) = tokens.popLast() { entry = NSDecimalNumber(decimal: number).stringValue }
                isEntering = true
                return
            }
            entry = String(entry.dropLast())
            if entry.isEmpty || entry == "-" { entry = "0" }
        case .operation(let operation):
            guard !hasError else { return }
            if justEvaluated { tokens = [.number(entryValue)]; justEvaluated = false }
            else if isEntering { tokens.append(.number(entryValue)) }
            if case .operation = tokens.last { tokens.removeLast() }
            tokens.append(.operation(operation))
            isEntering = false
        case .percent:
            guard !hasError else { return }
            do {
                var result = try Self.apply(entryValue, .divide, 100)
                if case .operation(let operation) = tokens.last, operation == .add || operation == .subtract {
                    let base = try Self.evaluate(Array(tokens.dropLast()))
                    result = try Self.apply(base, .multiply, result)
                }
                entry = NSDecimalNumber(decimal: result).stringValue
                isEntering = true
                if justEvaluated { tokens = []; justEvaluated = false }
            } catch { hasError = true }
        case .equals:
            guard !hasError else { return }
            do {
                if justEvaluated, let operation = repeatedOperation, let operand = repeatedOperand {
                    entry = NSDecimalNumber(decimal: try Self.apply(entryValue, operation, operand)).stringValue
                    return
                }
                var expression = tokens
                if expression.isEmpty || isEntering || selectedOperation != nil { expression.append(.number(entryValue)) }
                if expression.count >= 3,
                   case .operation(let operation) = expression[expression.count - 2],
                   case .number(let operand) = expression.last {
                    repeatedOperation = operation; repeatedOperand = operand
                } else { repeatedOperation = nil; repeatedOperand = nil }
                entry = NSDecimalNumber(decimal: try Self.evaluate(expression)).stringValue
                completedExpression = expression
                tokens = []; justEvaluated = true; isEntering = true
            } catch { hasError = true }
        }
    }

    private mutating func prepareEntry() {
        if justEvaluated || hasError { self = Self() }
        if !isEntering { entry = "0"; isEntering = true }
    }

    private static func format(_ value: Decimal, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        let magnitude = value < 0 ? -value : value
        let scientific = magnitude >= Decimal(10_000_000_000_000_000) || (magnitude > 0 && magnitude < Decimal(1) / Decimal(1_000_000_000))
        formatter.numberStyle = scientific ? .scientific : .decimal
        formatter.exponentSymbol = "e"
        formatter.usesGroupingSeparator = false
        formatter.usesSignificantDigits = true
        formatter.maximumSignificantDigits = 16
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0"
    }

    private static func evaluate(_ expression: [Token]) throws -> Decimal {
        guard case .number(let first) = expression.first else { throw CalculationError.invalidExpression }
        var term = first
        var terms: [Decimal] = []
        var operations: [Operation] = []
        var index = 1
        while index < expression.count {
            guard index + 1 < expression.count,
                  case .operation(let operation) = expression[index],
                  case .number(let right) = expression[index + 1] else { throw CalculationError.invalidExpression }
            if operation == .multiply || operation == .divide { term = try apply(term, operation, right) }
            else { terms.append(term); operations.append(operation); term = right }
            index += 2
        }
        terms.append(term)
        var result = terms[0]
        for (index, operation) in operations.enumerated() { result = try apply(result, operation, terms[index + 1]) }
        return result
    }

    private static func apply(_ left: Decimal, _ operation: Operation, _ right: Decimal) throws -> Decimal {
        var left = left, right = right, result = Decimal()
        let status: Decimal.CalculationError
        switch operation {
        case .add: status = NSDecimalAdd(&result, &left, &right, .plain)
        case .subtract: status = NSDecimalSubtract(&result, &left, &right, .plain)
        case .multiply: status = NSDecimalMultiply(&result, &left, &right, .plain)
        case .divide:
            guard right != 0 else { throw CalculationError.divisionByZero }
            status = NSDecimalDivide(&result, &left, &right, .plain)
        }
        guard status == .noError || status == .lossOfPrecision, !result.isNaN else { throw CalculationError.overflow }
        return result
    }
}
