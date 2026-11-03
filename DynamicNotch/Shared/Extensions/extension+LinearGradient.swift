//
//  extension+LinearGradient.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/16/26.
//

import SwiftUI

extension LinearGradient {
    static var orangeGradient: LinearGradient {
        LinearGradient(
            colors: [.orange, .yellow, .orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var logoGradient: LinearGradient {
        LinearGradient(
            colors: [.yellow.opacity(0.7), .indigo],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
    }
}
