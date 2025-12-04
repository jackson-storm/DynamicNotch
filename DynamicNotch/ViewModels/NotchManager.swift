import Combine
import SwiftUI

class NotchManager: ObservableObject {
    @Published var activeModules: [any NotchModule] = []
    
    var topModule: (any NotchModule)? { activeModules.first }

    func show(_ module: any NotchModule, autoHideAfter seconds: TimeInterval? = nil) {
        if !activeModules.contains(where: { $0.id == module.id }) {
            activeModules.append(module)
        }
        sortModules()
        if let s = seconds {
            DispatchQueue.main.asyncAfter(deadline: .now() + s) {
                self.hide(module)
            }
        }
    }

    func hide(_ module: any NotchModule) {
        activeModules.removeAll { $0.id == module.id }
    }

    private func sortModules() {
        activeModules.sort { $0.priority > $1.priority }
    }
}
