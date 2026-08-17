//
//  LanguageChangedNotchView.swift
//  DynamicNotch
//

import SwiftUI

struct LanguageChangedNotchView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @Environment(\.notchScale) private var scale
    
    let language: DynamicNotchLanguage
    
    var body: some View {
        HStack(spacing: 8) {
            if let flagName = language.flagAssetName {
                Image(flagName, bundle: .main)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: isDynamicIsland ? 24 : 30, height: isDynamicIsland ? 16 : 20)
                    .clipShape(RoundedRectangle(cornerRadius: isDynamicIsland ? 3 : 4, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: isDynamicIsland ? 3 : 4, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                    }
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            Text(verbatim: language.nativeDisplayName)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.leading, isDynamicIsland ? 6.scaled(by: scale) : 15.scaled(by: scale))
        .padding(.trailing, isDynamicIsland ? 8.scaled(by: scale) : 15.scaled(by: scale))
        .padding(.vertical, 10)
    }
}
