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
        isLiveActivityExpanded &&
        (content?.isExpandable ?? false)
    }

    var presentationID: String? {
        guard let content else { return nil }

        if isPresentingExpandedLiveActivity {
            return "\(content.id).expanded"
        }

        return content.id
    }

    var size: CGSize {
        guard let content else { return .init(width: baseWidth, height: baseHeight) }

        if isPresentingExpandedLiveActivity {
            if isDynamicIsland, let customizable = content as? DynamicIslandCustomizable {
                return customizable.expandedDynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight)
            }
            return content.expandedSize(baseWidth: baseWidth, baseHeight: baseHeight)
        }

        if isDynamicIsland, let customizable = content as? DynamicIslandCustomizable {
            return customizable.dynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight)
        }
        return content.size(baseWidth: baseWidth, baseHeight: baseHeight)
    }
    
    var cornerRadius: (top: CGFloat, bottom: CGFloat) {
        let baseRadius = baseHeight / 3
        guard let content else { return (top: baseRadius - 4, bottom: baseRadius) }

        if isPresentingExpandedLiveActivity {
            return content.expandedCornerRadius(baseRadius: baseRadius)
        }

        return content.cornerRadius(baseRadius: baseRadius)
    }
    
    var strokeColor: Color { content?.strokeColor ?? .clear }
    
    var updateToken = UUID()
    
    static func == (lhs: NotchModel, rhs: NotchModel) -> Bool {
        lhs.content?.id == rhs.content?.id &&
        lhs.isLiveActivityExpanded == rhs.isLiveActivityExpanded &&
        lhs.updateToken == rhs.updateToken
    }
}
