//
//  AnyTransition.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/14/26.
//

import SwiftUI

extension AnyTransition {
    static var blurAndFade: AnyTransition {
        .modifier(
            active: BlurFadeModifier(blur: 20, opacity: 0),
            identity: BlurFadeModifier(blur: 0, opacity: 1)
        )
    }
}
