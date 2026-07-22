//
//  FileConverterActiveNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/7/26.
//

import SwiftUI
internal import AppKit

struct FileConverterActiveNotchView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    
    @ObservedObject var fileConverterViewModel: FileConverterViewModel
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore

    var body: some View {
        HStack {
            Image(systemName: "document.fill")
                .font(.system(size: isDynamicIsland ? 16 : 18, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            statusIcon
        }
        .padding(.leading, isDynamicIsland ? 8.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.trailing, isDynamicIsland ? 4.scaled(by: scale) : 12.scaled(by: scale))
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch fileConverterViewModel.status {
        case .idle:
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(Color.blue)
                .font(.system(size: isDynamicIsland ? 16 : 18, weight: .semibold))

        case .converting:
            FileConverterConvertingIndicator()
                .frame(width: isDynamicIsland ? 16 : 18, height: isDynamicIsland ? 16 : 18)
                .padding(.trailing, 2.scaled(by: scale))

        case .converted:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.green)
                .font(.system(size: isDynamicIsland ? 16 : 18, weight: .semibold))

        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.yellow)
                .font(.system(size: isDynamicIsland ? 16 : 18, weight: .semibold))
        }
    }
}
