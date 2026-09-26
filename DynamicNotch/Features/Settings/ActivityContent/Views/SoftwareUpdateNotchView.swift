//
//  SoftwareUpdateNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/17/26.
//

import SwiftUI

struct SoftwareUpdateNotchView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    
    var body: some View {
        HStack {
            Image("logo")
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFill()
                .frame(width: isNotchlessScreen ? 18 : 24, height: isNotchlessScreen ? 18 : 24)
                .cornerRadius(6)
            
            Spacer()
            
            Image(systemName: "arrow.down.circle.dotted")
                .font(.system(size: isNotchlessScreen ? 18 : 21, weight: .semibold))
                .foregroundStyle(.blue)
        }
        .padding(.leading, isNotchlessScreen ? 6.scaled(by: scale) : 13.scaled(by: scale))
        .padding(.trailing, isNotchlessScreen ? 2.scaled(by: scale) : 11.scaled(by: scale))
    }
}

struct SoftwareUpdateExpandedNotchView: View {
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
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
                    .frame(width: 40, height: 40)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Update Available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Version \(updater.latestVersionString)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Button(action: {
                    updater.checkForUpdates()
                }) {
                    Image(systemName: "arrow.down.circle.dotted")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .blue.opacity(0.25)))
            }
        }
        .padding(.leading, isNotchlessScreen ? 20 : 42)
        .padding(.trailing, isNotchlessScreen ? 20 : 38)
        .padding(.bottom, isNotchlessScreen ? 20 : 14)
    }
}
