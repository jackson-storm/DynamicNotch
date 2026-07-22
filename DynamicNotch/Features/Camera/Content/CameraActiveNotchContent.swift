import SwiftUI

struct CameraActiveNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.HomePage.active.id
    
    var priority: Int { NotchContentRegistry.HomePage.active.priority }
    var isExpandable: Bool { true }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth, height: baseHeight)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        let isStarted = UserDefaults.standard.bool(forKey: "isCameraStarted")
        return (top: isStarted ? 34 : 24, bottom: isStarted ? 48 : 38)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let isStarted = UserDefaults.standard.bool(forKey: "isCameraStarted")
        let isLarge = UserDefaults.standard.bool(forKey: "isCameraLarge")
        
        if !isStarted {
            return .init(width: baseWidth + 65, height: baseHeight + 125)
        }
        if isLarge {
            return .init(width: baseWidth + 250, height: baseHeight + 220)
        } else {
            return .init(width: baseWidth + 180, height: baseHeight + 180)
        }
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let isStarted = UserDefaults.standard.bool(forKey: "isCameraStarted")
        let isLarge = UserDefaults.standard.bool(forKey: "isCameraLarge")
        
        if !isStarted {
            return .init(width: baseWidth + 95, height: baseHeight + 125)
        }
        if isLarge {
            return .init(width: baseWidth + 280, height: baseHeight + 220)
        } else {
            return .init(width: baseWidth + 210, height: baseHeight + 180)
        }
    }
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        let isStarted = UserDefaults.standard.bool(forKey: "isCameraStarted")
        let isLarge = UserDefaults.standard.bool(forKey: "isCameraLarge")
        
        if !isStarted {
            return baseHeight * 0.2
        }
        if isLarge {
            return baseHeight * 0.15
        } else {
            return baseHeight * 0.2
        }
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(EmptyView())
    }
}
