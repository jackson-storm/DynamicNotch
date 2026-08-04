import Foundation

enum CalendarTimeDisplayFormat: String, CaseIterable, Identifiable, Codable {
    case exact
    case relative
    case both

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .exact:
            return "settings.activities.calendar.timeDisplayFormat.exact"
        case .relative:
            return "settings.activities.calendar.timeDisplayFormat.relative"
        case .both:
            return "settings.activities.calendar.timeDisplayFormat.both"
        }
    }
}
