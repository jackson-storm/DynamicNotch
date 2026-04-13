//
//  notchModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/18/26.
//

import Foundation
import SwiftUI

enum NotchState {
    case showLiveActivity(NotchContentProtocol)
    case hideLiveActivity(id: String)
    case dismissLiveActivity(id: String)
    case showTemporaryNotification(NotchContentProtocol, duration: TimeInterval)
    case hide
}

struct NotchModel: Equatable {
    var liveActivityContent: NotchContentProtocol? = nil
    var temporaryNotificationContent: NotchContentProtocol? = nil
    var isLiveActivityExpanded = false
    var content: NotchContentProtocol? { temporaryNotificationContent ?? liveActivityContent }
    
    var baseWidth: CGFloat = 190
    var baseHeight: CGFloat = 38
    var scale: CGFloat = 1.0
    
    var isPresentingExpandedLiveActivity: Bool {
        temporaryNotificationContent == nil &&
        isLiveActivityExpanded &&
        (liveActivityContent?.isExpandable ?? false)
    }

    var presentationID: String? {
        guard let content else { return nil }

        if isPresentingExpandedLiveActivity {
            return "\(content.id).expanded"
        }

        return content.id
    }

    var size: CGSize {
        if let temporaryNotificationContent {
            return temporaryNotificationContent.size(baseWidth: baseWidth, baseHeight: baseHeight)
        }

        if let liveActivityContent {
            if isPresentingExpandedLiveActivity {
                return liveActivityContent.expandedSize(baseWidth: baseWidth, baseHeight: baseHeight)
            }

            return liveActivityContent.size(baseWidth: baseWidth, baseHeight: baseHeight)
        }

        return .init(width: baseWidth, height: baseHeight)
    }
    
    var cornerRadius: (top: CGFloat, bottom: CGFloat) {
        let baseRadius = baseHeight / 3

        if let temporaryNotificationContent {
            return temporaryNotificationContent.cornerRadius(baseRadius: baseRadius)
        }

        if let liveActivityContent {
            if isPresentingExpandedLiveActivity {
                return liveActivityContent.expandedCornerRadius(baseRadius: baseRadius)
            }

            return liveActivityContent.cornerRadius(baseRadius: baseRadius)
        }

        return (top: baseRadius - 4, bottom: baseRadius)
    }
    
    var strokeColor: Color { content?.strokeColor ?? .clear }
    
    var offsetXTransition: CGFloat {
        if let temporaryNotificationContent {
            return temporaryNotificationContent.offsetXTransition
        }

        if let liveActivityContent {
            if isPresentingExpandedLiveActivity {
                return liveActivityContent.expandedOffsetXTransition
            }

            return liveActivityContent.offsetXTransition
        }

        return 0
    }
    
    var offsetYTransition: CGFloat {
        if let temporaryNotificationContent {
            return temporaryNotificationContent.offsetYTransition
        }

        if let liveActivityContent {
            if isPresentingExpandedLiveActivity {
                return liveActivityContent.expandedOffsetYTransition
            }

            return liveActivityContent.offsetYTransition
        }

        return 0
    }
    
    static func == (lhs: NotchModel, rhs: NotchModel) -> Bool {
        lhs.content?.id == rhs.content?.id &&
        lhs.isLiveActivityExpanded == rhs.isLiveActivityExpanded
    }
}
