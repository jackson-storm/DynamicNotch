//
//  LyricLine.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/13/26.
//

import Foundation

struct LyricLine: Identifiable, Equatable, Sendable {
    let id: Int
    let startTime: TimeInterval?
    let text: String
}
