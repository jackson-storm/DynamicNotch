//
//  notchModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/18/26.
//

import Foundation
import SwiftUI

enum NotchEvent {
    case showLiveActivitiy(NotchContentProvider)
    case showTemporaryNotification(NotchContentProvider, duration: TimeInterval)
    case hide
}

struct NotchModel: Equatable {
    var liveActivityContent: NotchContentProvider? = nil
    var temporaryNotificationContent: NotchContentProvider? = nil
    
    var content: NotchContentProvider? {
        temporaryNotificationContent ?? liveActivityContent
    }
    
    var baseWidth: CGFloat = 188
    var baseHeight: CGFloat = 38
    var scale: CGFloat = 1.0
    
    var size: CGSize {
        content?.size(baseWidth: baseWidth, baseHeight: baseHeight) ?? .init(width: baseWidth, height: baseHeight)
    }
    
    var cornerRadius: (top: CGFloat, bottom: CGFloat) {
        let baseRadius = baseHeight / 3
        return content?.cornerRadius(baseRadius: baseRadius) ?? (top: baseRadius - 4, bottom: baseRadius)
    }
    
    var strokeColor: Color {
        content?.strokeColor ?? .clear
    }
    
    var offsetYTransition: CGFloat {
        content?.offsetYTransition ?? 0
    }
    
    static func == (lhs: NotchModel, rhs: NotchModel) -> Bool {
        lhs.content?.id == rhs.content?.id
    }
}

