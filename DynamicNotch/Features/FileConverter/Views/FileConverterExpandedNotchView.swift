//
//  FileConverterExpandedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/7/26.
//

import SwiftUI

struct FileConverterExpandedActiveNotchView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    
    @ObservedObject var fileConverterViewModel: FileConverterViewModel
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    
    var onRequestCollapse: (@MainActor () -> Void)? = nil
    
    private var statusThemeColor: Color {
        switch fileConverterViewModel.status {
        case .converted:
            return .green
        case .converting:
            return .blue
        case .failed:
            return .orange
        case .idle:
            return .blue
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.1))
                .frame(width: 32, height: 32)
            
            switch fileConverterViewModel.status {
            case .idle:
                Image(systemName: "arrow.right")
                    .foregroundStyle(.white.opacity(0.6))
                    .font(.system(size: 14, weight: .semibold))

            case .converting:
                FileConverterConvertingIndicator()
                    .frame(width: 18, height: 18)

            case .converted:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 18, weight: .semibold))

            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 16, weight: .semibold))
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            selectedFileRow
            
            if fileConverterViewModel.item != nil {
                buttonActionRow
            }
        }
        .padding(.horizontal, isDynamicIsland ? 12 : 36)
        .padding(.bottom, 10)
    }
    
    private var selectedFileRow: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
                .frame(height: 76)
            
            HStack(spacing: 0) {
                chooseFileRow
                statusIcon
                menuFormatRow
            }
        }
    }
    
    private var chooseFileRow: some View {
        Button(action: {
            onRequestCollapse?()
            DispatchQueue.main.async {
                fileConverterViewModel.chooseFileFromFinder()
            }
        }) {
            ZStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 18,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .fill(.white.opacity(0.04))
                .frame(height: 76)
                
                VStack(alignment: .center, spacing: 3) {
                    if let item = fileConverterViewModel.item {
                        Image(nsImage: item.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        
                        MarqueeText(
                            .constant(item.displayName),
                            font: .system(size: 11, weight: .medium),
                            nsFont: .headline,
                            textColor: .white.opacity(0.85),
                            backgroundColor: .clear,
                            minDuration: 1.0,
                            frameWidth: 80.scaled(by: scale),
                            shortTextAlignment: .center
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .disabled(fileConverterViewModel.isConverting)
        .buttonStyle(.plain)
    }
    
    private var menuFormatRow: some View {
        Menu {
            ForEach(fileConverterViewModel.availableFormats) { format in
                Button(format.title) {
                    fileConverterViewModel.selectedFormat = format
                }
            }
        } label: {
            ZStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 18,
                    topTrailingRadius: 18
                )
                .fill(.white.opacity(0.04))
                .frame(height: 76)
                
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Text(fileConverterViewModel.selectedFormat.title)
                            .lineLimit(1)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    Text(verbatim: "Format")
                        .lineLimit(1)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 8)
            }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .disabled(fileConverterViewModel.isConverting)
    }
    
    private var buttonActionRow: some View {
        HStack {
            if fileConverterViewModel.item != nil && !fileConverterViewModel.isConverting {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        fileConverterViewModel.clear()
                    }
                }) {
                    Text(verbatim: "Close Converter")
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .buttonStyle(PrimaryButtonStyle(height: 36, backgroundColor: .white.opacity(0.12)))
                .disabled(fileConverterViewModel.isConverting)
                
                Spacer()
                
                if case .converted(let outputURL) = fileConverterViewModel.status {
                    Button(action: {
                        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                    }) {
                        Text("Show in Finder")
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(PrimaryButtonStyle(height: 36, backgroundColor: .blue.opacity(0.2)))
                    
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            fileConverterViewModel.convert(
                                options: FileConverterConversionOptions(settings: mediaSettings)
                            )
                        }
                        onRequestCollapse?()
                    }) {
                        Text(verbatim: fileConverterViewModel.isConverting ? "Converting..." : "Convert to \(fileConverterViewModel.selectedFormat.title)")
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(PrimaryButtonStyle(height: 36, backgroundColor: .blue.opacity(0.2)))
                    .disabled(fileConverterViewModel.isConverting || fileConverterViewModel.item == nil)
                }
            }
        }
    }
}
