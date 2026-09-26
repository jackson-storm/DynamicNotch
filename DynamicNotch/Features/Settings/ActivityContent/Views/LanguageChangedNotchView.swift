//
//  LanguageChangedNotchView.swift
//  DynamicNotch
//

import SwiftUI

struct LanguageChangedNotchView: View {
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
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
                    .frame(width: isNotchlessScreen ? 24 : 30, height: isNotchlessScreen ? 16 : 20)
                    .clipShape(RoundedRectangle(cornerRadius: isNotchlessScreen ? 3 : 4, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: isNotchlessScreen ? 3 : 4, style: .continuous)
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
        .padding(.leading, isNotchlessScreen ? 6.scaled(by: scale) : 15.scaled(by: scale))
        .padding(.trailing, isNotchlessScreen ? 8.scaled(by: scale) : 15.scaled(by: scale))
        .padding(.vertical, 10)
    }
}
