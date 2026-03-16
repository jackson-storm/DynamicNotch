import Combine
import Foundation

@MainActor
final class SettingsRootViewModel: ObservableObject {
    enum Section: String, CaseIterable, Identifiable {
        case general
        case liveActivity
        case temporaryActivity
        case about

        var id: String { rawValue }

        var title: String {
            switch self {
            case .general:
                return "General"
            case .liveActivity:
                return "Live Activity"
            case .temporaryActivity:
                return "Temporary"
            case .about:
                return "About"
            }
        }

        var subtitle: String {
            switch self {
            case .general:
                return "App startup, placement and notch shape"
            case .liveActivity:
                return "Persistent notch events"
            case .temporaryActivity:
                return "Short-lived notch notifications"
            case .about:
                return "Project, links and feature overview"
            }
        }

        var systemImage: String {
            switch self {
            case .general:
                return "gearshape.fill"
            case .liveActivity:
                return "waveform.path.ecg.rectangle.fill"
            case .temporaryActivity:
                return "timer"
            case .about:
                return "info.circle.fill"
            }
        }

        var accessibilityIdentifier: String {
            "settings.tab.\(rawValue)"
        }
    }

    @Published var selection: Section {
        didSet {
            defaults.set(selection.rawValue, forKey: Self.selectionKey)
        }
    }

    let liveActivityViewModel: LiveActivitySettingsViewModel
    let temporaryActivityViewModel: TemporaryActivitySettingsViewModel

    private let defaults: UserDefaults
    private static let selectionKey = "settings.root.selection"

    init(
        settings: GeneralSettingsViewModel,
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        let storedSelection = defaults.string(forKey: Self.selectionKey) ?? ""

        switch storedSelection {
        case "activities":
            self.selection = .liveActivity
        default:
            self.selection = Section(rawValue: storedSelection) ?? .general
        }

        self.liveActivityViewModel = LiveActivitySettingsViewModel(settings: settings)
        self.temporaryActivityViewModel = TemporaryActivitySettingsViewModel(settings: settings)
    }

    var sections: [Section] {
        Section.allCases
    }
}
