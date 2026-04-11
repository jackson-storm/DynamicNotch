//
//  SettingsSidebarRow.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/4/26.
//

import SwiftUI

struct SettingsSidebarRow: View {
    let title: String
    let systemImage: String?
    let imageName: String?
    let tint: Color

    init(title: String, systemImage: String, tint: Color) {
        self.title = title
        self.systemImage = systemImage
        self.imageName = nil
        self.tint = tint
    }

    init(title: String, imageName: String, tint: Color) {
        self.title = title
        self.systemImage = nil
        self.imageName = imageName
        self.tint = tint
    }
    
    var body: some View {
        Label {
            Text(title)
        } icon: {
            if let systemImage {
                SettingsIconBadge(
                    systemImage: systemImage,
                    tint: tint,
                    size: 22,
                    iconSize: 12,
                    cornerRadius: 6
                )
            } else if let imageName {
                SettingsIconBadge(
                    imageName: imageName,
                    tint: tint,
                    size: 22,
                    iconSize: 12,
                    cornerRadius: 6
                )
            }
        }
    }
}
