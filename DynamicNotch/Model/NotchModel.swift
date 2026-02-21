//
//  notchModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/18/26.
//

import Foundation

enum NotchContent: Hashable {
    case none
    case music
    case charger
    case lowPower
    case fullPower
    case bluetooth
    case systemHud(HUDType)
    case onboarding
    case vpn(NetworkEvent)
}

struct NotchState: Equatable {
    var activeContent: NotchContent = .none
    var temporaryContent: NotchContent? = nil
    var isExpanded: Bool = false
    var content: NotchContent { temporaryContent ?? activeContent }
    
    var baseWidth: CGFloat = 226
    var baseHeight: CGFloat = 38
    
    var size: CGSize {
        switch content {
        case .none: return .init(width: baseWidth, height: baseHeight)
            
        case .music: return .init(width: isExpanded ? baseWidth + 200 : baseWidth + 80, height: isExpanded ? baseHeight + 150 : baseHeight)
        case .onboarding: return .init(width: baseWidth + 70, height: baseHeight + 120)
            
        case .charger: return .init(width: baseWidth + 180, height: baseHeight)
        case .lowPower: return .init(width: baseWidth + 140, height: baseHeight + 80)
        case .fullPower: return .init(width: baseWidth + 90, height: baseHeight + 70)
            
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
        case .music: return (top: isExpanded ? 32 : baseRadius, bottom: isExpanded ? 46 : baseRadius)
        case .fullPower: return (top: 18, bottom: 36)
        case .lowPower: return (top: 22, bottom: 40)
        case .onboarding: return (top: 28, bottom: 36)
            
        default: return (top: baseRadius - 4, bottom: baseRadius)
            
        }
    }
    
    var offsetXTransition: CGFloat {
        switch content {
        case .fullPower: return -140
        case .onboarding: return -150
            
        default: return -160
        }
    }
    
    var offsetYTransition: CGFloat {
        switch content {
        case .music: return isExpanded ? -60 : 0
        case .lowPower: return -60
        case .fullPower: return -40
        case .onboarding: return -80
            
        default: return -10
            
        }
    }
}
