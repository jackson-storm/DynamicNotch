//
//  extension+Int.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/23/26.
//

import Foundation

extension Int {
    func scaled(by scale: CGFloat) -> CGFloat {
        return CGFloat(self) * scale
    }
}
