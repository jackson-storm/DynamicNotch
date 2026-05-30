//
//  notchModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/18/26.
//

import Foundation
import SwiftUI

struct NotchModel: Equatable {
    var liveActivityContent: NotchContentProtocol? = nil
    var temporaryNotificationContent: NotchContentProtocol? = nil
    var isLiveActivityExpanded = false
    var content: NotchContentProtocol? { temporaryNotificationContent ?? liveActivityContent }
    
    var baseWidth: CGFloat = 190
    var baseHeight: CGFloat = 38
    var scale: CGFloat = 1.0
    var isDynamicIsland = false
    
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
            if isDynamicIsland, let customizable = temporaryNotificationContent as? DynamicIslandCustomizable {
                return customizable.dynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight)
            }
            return temporaryNotificationContent.size(baseWidth: baseWidth, baseHeight: baseHeight)
        }

        if let liveActivityContent {
            if isPresentingExpandedLiveActivity {
                if isDynamicIsland, let customizable = liveActivityContent as? DynamicIslandCustomizable {
                    return customizable.expandedDynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight)
                }
                return liveActivityContent.expandedSize(baseWidth: baseWidth, baseHeight: baseHeight)
            }

            if isDynamicIsland, let customizable = liveActivityContent as? DynamicIslandCustomizable {
                return customizable.dynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight)
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
    
    var updateToken = UUID()
    
    static func == (lhs: NotchModel, rhs: NotchModel) -> Bool {
        lhs.content?.id == rhs.content?.id &&
        lhs.isLiveActivityExpanded == rhs.isLiveActivityExpanded &&
        lhs.updateToken == rhs.updateToken
    }
}
