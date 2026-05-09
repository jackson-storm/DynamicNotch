//
//  FileConverterExpandedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/7/26.
//

import SwiftUI

struct FileConverterExpandedActiveNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var fileConverterViewModel: FileConverterViewModel
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore

    let onRequestCollapse: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            conversionRow
            actionRow
        }
        .padding(.horizontal, 43)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var conversionRow: some View {
        if let item = fileConverterViewModel.item {
            HStack(spacing: 10) {
                VStack(spacing: 3) {
                    Image(nsImage: item.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)

                    MarqueeText(
                        .constant(item.displayName),
                        font: .system(size: 12, weight: .medium),
                        nsFont: .headline,
                        textColor: .white.opacity(0.8),
                        backgroundColor: .clear,
                        minDuration: 1.0,
                        frameWidth: 85.scaled(by: scale)
                    )
                }
                .padding(.horizontal, 12)
                .frame(height: 85)

                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))

                Spacer()

                Menu {
                    ForEach(FileConverterOutputFormat.allCases) { format in
                        Button(format.title) {
                            fileConverterViewModel.selectedFormat = format
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(fileConverterViewModel.selectedFormat.title)
                            .lineLimit(1)
                            .font(.system(size: 17, weight: .bold))
                        Text(verbatim: "Format")
                            .lineLimit(1)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.58))
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.white.opacity(0.1))
                    )
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .disabled(fileConverterViewModel.isConverting)
                
                Spacer()
            }
        }
    }

    private var actionRow: some View {
        HStack {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    fileConverterViewModel.clear()
                }
            }) {
                Text(verbatim: "Close Converter")
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .gray.opacity(0.2)))
            .disabled(fileConverterViewModel.isConverting)

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    fileConverterViewModel.convert()
                }
                onRequestCollapse()
            }) {
                Text(verbatim: "Convert to \(fileConverterViewModel.selectedFormat.title)")
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .blue.opacity(0.2)))
            .disabled(fileConverterViewModel.isConverting)
        }
    }
}
