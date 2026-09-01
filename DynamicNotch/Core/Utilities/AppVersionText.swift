//
//  AppVersionText.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/8/26.
//

internal import AppKit

enum AppVersionText {
    static var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        
        switch (version) {
        case let (version?):
            return "v\(version)"
        default:
            return "DynamicNotch"
        }
    }
}
