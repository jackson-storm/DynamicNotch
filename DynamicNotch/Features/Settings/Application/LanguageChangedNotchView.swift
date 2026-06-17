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
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isDynamicIsland ? 24 : 30, height: isDynamicIsland ? 14 : 20)
                    .clipShape(RoundedRectangle(cornerRadius: isDynamicIsland ? 3 : 4))
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
        .padding(.horizontal, isDynamicIsland ? 6.scaled(by: scale) : 15.scaled(by: scale))
        .padding(.vertical, 10)
    }
}
