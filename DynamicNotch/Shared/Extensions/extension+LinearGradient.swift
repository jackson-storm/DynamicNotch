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
            colors: [.green, .cyan],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
    }
}
