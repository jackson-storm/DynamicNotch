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
    let showBadge: Bool

    init(title: String, systemImage: String, tint: Color, showBadge: Bool = false) {
        self.title = title
        self.systemImage = systemImage
        self.imageName = nil
        self.tint = tint
        self.showBadge = showBadge
    }

    init(title: String, imageName: String, tint: Color, showBadge: Bool = false) {
        self.title = title
        self.systemImage = nil
        self.imageName = imageName
        self.tint = tint
        self.showBadge = showBadge
    }
    
    var body: some View {
        HStack(spacing: 8) {
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
            
            if showBadge {
                Spacer()
                Circle()
                    .fill(Color.red)
                    .frame(width: 7, height: 7)
                    .shadow(color: .red.opacity(0.4), radius: 3)
            }
        }
    }
}
