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
        switch fileConverterViewModel.status {
        case .idle:
            Image(systemName: "arrow.right")
                .foregroundStyle(.white.opacity(0.6))
                .font(.system(size: 18, weight: .semibold))
            
        case .converting:
            FileConverterConvertingIndicator()
                .frame(width: 20, height: 20)
            
        case .converted:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 20, weight: .semibold))
            
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .font(.system(size: 20, weight: .semibold))
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            selectedFileRow
            buttonActionRow
        }
        .padding(.horizontal, isDynamicIsland ? 12 : 36)
        .padding(.bottom, 10)
    }
    
    private var selectedFileRow: some View {
        HStack(spacing: 6) {
            chooseFileRow
            statusIcon
            menuFormatRow
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
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white.opacity(0.1))
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
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white.opacity(0.1))
                    .frame(height: 76)
                
                HStack(spacing: 8) {
                    VStack(spacing: 2) {
                        Text(fileConverterViewModel.selectedFormat.title)
                            .lineLimit(1)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text(verbatim: "Format")
                            .lineLimit(1)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .disabled(fileConverterViewModel.isConverting)
    }
    
    private var buttonActionRow: some View {
        HStack {
            Button(action: { fileConverterViewModel.clear()}) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .buttonStyle(PrimaryButtonStyle(width: 40, height: 40, backgroundColor: .white.opacity(0.12)))
            .disabled(fileConverterViewModel.isConverting)
            .opacity(fileConverterViewModel.isConverting ? 0.6 : 1.0)
            
            Button(action: {
                onRequestCollapse?()
                SettingsWindowController.shared.showWindow(selecting: .fileConverter)
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .buttonStyle(PrimaryButtonStyle(width: 40, height: 40, backgroundColor: .white.opacity(0.12)))
            
            Spacer()
            
            if case .converted(let outputURL) = fileConverterViewModel.status {
                Button(action: { NSWorkspace.shared.activateFileViewerSelecting([outputURL])}) {
                    Text("Show in Finder")
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PrimaryButtonStyle(height: 40, backgroundColor: .blue.opacity(0.25)))
                
            } else {
                Button(action: {
                    fileConverterViewModel.convert(options: FileConverterConversionOptions(settings: mediaSettings))
                    onRequestCollapse?()
                }) {
                    Text(verbatim: fileConverterViewModel.isConverting
                         ? "Converting file to \(fileConverterViewModel.selectedFormat.title)..."
                         : "Convert file to \(fileConverterViewModel.selectedFormat.title)")
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                }
                .buttonStyle(PrimaryButtonStyle(height: 40, backgroundColor: .blue.opacity(0.25)))
                .disabled(fileConverterViewModel.isConverting)
                .opacity(fileConverterViewModel.isConverting ? 0.6 : 1.0)
            }
        }
    }
}
