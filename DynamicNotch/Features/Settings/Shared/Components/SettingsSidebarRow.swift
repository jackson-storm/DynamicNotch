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
    let iconColor: Color
    let stroke: Bool
    let showBadge: Bool

    init(title: String, systemImage: String, tint: Color, iconColor: Color = .white, stroke: Bool = false, showBadge: Bool = false) {
        self.title = title
        self.systemImage = systemImage
        self.imageName = nil
        self.tint = tint
        self.iconColor = iconColor
        self.stroke = stroke
        self.showBadge = showBadge
    }

    init(title: String, imageName: String, tint: Color, iconColor: Color = .white, stroke: Bool = false, showBadge: Bool = false) {
        self.title = title
        self.systemImage = nil
        self.imageName = imageName
        self.tint = tint
        self.iconColor = iconColor
        self.stroke = stroke
        self.showBadge = showBadge
    }
    
    private var isMacOS27OrLater: Bool {
        if #available(macOS 27.0, *) {
            return true
        } else {
            return ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27
        }
    }

    private var iconSize: CGFloat {
        isMacOS27OrLater ? 10 : 12
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
                        iconColor: iconColor,
                        iconSize: iconSize,
                        cornerRadius: 6,
                        stroke: stroke
                    )
                } else if let imageName {
                    SettingsIconBadge(
                        imageName: imageName,
                        tint: tint,
                        size: 22,
                        iconColor: iconColor,
                        iconSize: iconSize,
                        cornerRadius: 6,
                        stroke: stroke
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
