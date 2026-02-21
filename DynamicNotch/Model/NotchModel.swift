//
//  notchModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/18/26.
//

import Foundation

enum NotchEvent {
    case showLiveActivitiy(NotchContent)
    case showTemporaryNotification(NotchContent, duration: TimeInterval)
    case hide
}

enum NotchContent: Hashable {
    case none
    case music(ExpandedEvent)
    case battery(PowerEvent)
    case bluetooth
    case systemHud(HudEvent)
    case onboarding
    case vpn(VpnEvent)
}

struct NotchState: Equatable {
    var liveActivityContent: NotchContent = .none
    var temporaryNotificationContent: NotchContent? = nil
    var content: NotchContent { temporaryNotificationContent ?? liveActivityContent }
    
    var baseWidth: CGFloat = 226
    var baseHeight: CGFloat = 38
    
    var size: CGSize {
        switch content {
        case .none: return .init(width: baseWidth, height: baseHeight)
            
        case .music(.none): return .init(width: baseWidth + 80, height: baseHeight)
        case .music(.expanded): return .init(width: baseWidth + 200, height: baseHeight + 150)
            
        case .onboarding: return .init(width: baseWidth + 70, height: baseHeight + 120)
            
        case .battery(.charger): return .init(width: baseWidth + 180, height: baseHeight)
        case .battery(.lowPower): return .init(width: baseWidth + 140, height: baseHeight + 80)
        case .battery(.fullPower): return .init(width: baseWidth + 90, height: baseHeight + 70)
            
        case .systemHud(.display): return .init(width: baseWidth + 200, height: baseHeight)
        case .systemHud(.keyboard): return .init(width: baseWidth + 200, height: baseHeight)
        case .systemHud(.volume): return .init(width: baseWidth + 200, height: baseHeight)
            
        case .bluetooth: return .init(width: baseWidth + 180, height: baseHeight)
            
        case .vpn(.connected): return .init(width: baseWidth + 180, height: baseHeight)
        case .vpn(.disconnected): return .init(width: baseWidth + 220, height: baseHeight)
            
        }
    }
    
    var cornerRadius: (top: CGFloat, bottom: CGFloat) {
        let baseRadius = baseHeight / 3
        
        switch content {
        case .battery(.fullPower): return (top: 18, bottom: 36)
        case .battery(.lowPower): return (top: 22, bottom: 40)
            
        case .onboarding: return (top: 28, bottom: 36)
        case .music(.expanded): return (top: 32, bottom: 46)
            
        default: return (top: baseRadius - 4, bottom: baseRadius)
            
        }
    }
    
    var offsetXTransition: CGFloat {
        switch content {
        case .battery(.fullPower): return -140
        case .onboarding: return -150
        case .music(.expanded): return -210
            
        default: return -160
            
        }
    }
    
    var offsetYTransition: CGFloat {
        switch content {
        case .battery(.lowPower): return -60
        case .battery(.fullPower): return -40
            
        case .onboarding: return -80
        case .music(.expanded): return -90
            
        default: return -10
            
        }
    }
}
