//
//  notchModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/18/26.
//

import Foundation
import SwiftUI

enum NotchState {
    case compact
    case expanded
}

enum NotchEvent {
    case showLiveActivitiy(NotchContent)
    case showTemporaryNotification(NotchContent, duration: TimeInterval)
    case hide
}

enum NotchContent: Hashable {
    case none
    case music(NotchState)
    case battery(PowerEvent)
    case bluetooth
    case systemHud(HudEvent)
    case onboarding
    case vpn(VpnEvent)
    
    var strokeColor: Color {
        switch self {
        case .battery(.charger): return .green.opacity(0.3)
        case .battery(.fullPower): return .green.opacity(0.3)
        case .battery(.lowPower): return .red.opacity(0.3)
        case .vpn(.disconnected): return .red.opacity(0.3)
        
        default: return .white.opacity(0.15)
        }
    }
}

struct NotchModel: Equatable {
    var liveActivityContent: NotchContent = .none
    var temporaryNotificationContent: NotchContent? = nil
    var content: NotchContent { temporaryNotificationContent ?? liveActivityContent }
    
    var baseWidth: CGFloat = 226
    var baseHeight: CGFloat = 38
    
    var size: CGSize {
        switch content {
        case .none: return .init(width: baseWidth, height: baseHeight)
            
        case .music(.compact): return .init(width: baseWidth + 80, height: baseHeight)
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
    
    var offsetYTransition: CGFloat {
        switch content {
        case .battery(.lowPower): return -60
        case .battery(.fullPower): return -60
        case .onboarding: return -60
        case .music(.expanded): return -60
            
        default: return 0
            
        }
    }
}
