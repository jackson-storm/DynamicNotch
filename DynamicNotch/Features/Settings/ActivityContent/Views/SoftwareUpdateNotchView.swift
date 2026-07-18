//
//  SoftwareUpdateNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/17/26.
//

import SwiftUI

struct SoftwareUpdateNotchView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    
    var body: some View {
        HStack {
            Image("logo")
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFill()
                .frame(width: isDynamicIsland ? 18 : 24, height: isDynamicIsland ? 18 : 24)
                .cornerRadius(6)
            
            Spacer()
            
            Image(systemName: "arrow.down.circle.dotted")
                .font(.system(size: isDynamicIsland ? 18 : 21, weight: .semibold))
                .foregroundStyle(.blue)
        }
        .padding(.leading, isDynamicIsland ? 6.scaled(by: scale) : 13.scaled(by: scale))
        .padding(.trailing, isDynamicIsland ? 2.scaled(by: scale) : 11.scaled(by: scale))
    }
}

struct SoftwareUpdateExpandedNotchView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland
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
                .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .blue.opacity(0.2)))
            }
        }
        .padding(.leading, isDynamicIsland ? 22 : 42)
        .padding(.trailing, isDynamicIsland ? 22 : 38)
        .padding(.bottom, isDynamicIsland ? 22 : 14)
    }
}
