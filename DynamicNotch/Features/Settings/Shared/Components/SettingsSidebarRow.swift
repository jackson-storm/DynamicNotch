//
//  SettingsSidebarRow.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/4/26.
//

import SwiftUI

struct SettingsSidebarRow: View {
    let title: String
    let systemImage: String
    let tint: Color
    
    var body: some View {
        Label {
            Text(title)
        } icon: {
            SettingsIconBadge(
                systemImage: systemImage,
                tint: tint,
                size: 22,
                iconSize: 12,
                cornerRadius: 6
            )
        }
    }
}
