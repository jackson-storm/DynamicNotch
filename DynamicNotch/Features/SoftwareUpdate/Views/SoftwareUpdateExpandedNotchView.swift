//
//  SoftwareUpdateExpandedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 10/21/26.
//

import SwiftUI

struct SoftwareUpdateExpandedNotchView: View {
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @Environment(\.locale) private var locale
    @ObservedObject private var updater = SparkleUpdater.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Spacer()
            
            HStack(alignment: .center, spacing: 12) {
                Image("logo")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFill()
                    .frame(width: 45, height: 45)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(locale.dn("notch.softwareUpdate.available", fallback: "Update Available"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(locale.dnFormat("notch.softwareUpdate.version", fallback: "Version %@", updater.latestVersionString))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, isNotchlessScreen ? 6 : 0)
                
                Spacer()
                
                Button(action: {
                    updater.checkForUpdates()
                }) {
                    Image(systemName: "arrow.down.circle.dotted")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PrimaryButtonStyle(width: 50, height: 50, backgroundColor: .blue.opacity(0.25)))
            }
            
            Spacer()
        }
        .padding(.top, isNotchlessScreen ? 0 : 25)
        .padding(.leading, isNotchlessScreen ? 20 : 38)
        .padding(.trailing, isNotchlessScreen ? 15 : 34)
    }
}
