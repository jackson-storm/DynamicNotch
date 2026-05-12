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
    @ObservedObject var fileConverterViewModel: FileConverterViewModel
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore

    var body: some View {
        HStack {
            Image(systemName: "document.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            statusIcon
        }
        .padding(.leading, 14.scaled(by: scale))
        .padding(.trailing, 12.scaled(by: scale))
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch fileConverterViewModel.status {
        case .idle:
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(Color.accentColor)
                .font(.system(size: 18, weight: .semibold))

        case .converting:
            FileConverterConvertingIndicator()
                .frame(width: 18, height: 18)
                .padding(.trailing, 2.scaled(by: scale))

        case .converted:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.green)
                .font(.system(size: 18, weight: .semibold))

        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.yellow)
                .font(.system(size: 18, weight: .semibold))
        }
    }
}
