//
//  notchModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/18/26.
//

import Foundation

struct NotchState: Equatable {
    var activeContent: NotchContent = .none
    var temporaryContent: NotchContent? = nil
    var isExpanded: Bool = false
    var content: NotchContent { temporaryContent ?? activeContent }
    
    var baseWidth: CGFloat = 226
    var baseHeight: CGFloat = 38
    
    var size: CGSize {
        switch content {
        case .none:
            return .init(width: baseWidth, height: baseHeight)
            
        case .music:
            if isExpanded {
                return .init(width: 400, height: 190)
            } else {
                return .init(width: baseWidth + 80, height: baseHeight)
            }
            
        case .lowPower, .fullPower:
            return .init(width: 360, height: 110)
            
        default:
            return .init(width: baseWidth + 120, height: baseHeight)
        }
    }
    
    var cornerRadius: (top: CGFloat, bottom: CGFloat) {
        let baseRadius = baseHeight / 3
        
        switch content {
        case .music:
            if isExpanded {
                return (top: 32, bottom: 46)
            } else {
                return (top: baseRadius, bottom: baseRadius)
            }
            
        case .lowPower, .fullPower:
            return (top: 18, bottom: 36)
            
        default:
            return (top: baseRadius - 4, bottom: baseRadius)
        }
    }
    
    var offsetXTransition: CGFloat {
        switch content {
        case .none: return 0
        case .music: return -60
        case .charger: return -60
        case .lowPower: return -60
        case .fullPower: return -40
        case .bluetooth: return -60
        case .systemHud: return -60
        }
    }
    
    var offsetYTransition: CGFloat {
        switch content {
        case .none: return 0
        case .music: return isExpanded ? -60 : 0
        case .charger: return 0
        case .lowPower: return -60
        case .fullPower: return -40
        case .bluetooth: return 0
        case .systemHud: return 0
        }
    }
}

enum NotchContent: Hashable {
    case none
    case music
    case charger
    case lowPower
    case fullPower
    case bluetooth
    case systemHud(HUDType)
}
