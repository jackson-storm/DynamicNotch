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
    
    private var strokeColor: Color {
        switch fileConverterViewModel.status {
        case .converted:
                .green.opacity(0.6)
        case .converting:
                .blue.opacity(0.6)
        case .failed:
                .yellow.opacity(0.6)
        case .idle:
                .blue.opacity(0.6)
        }
    }
    
    private var fillColor: Color {
        switch fileConverterViewModel.status {
        case .converted:
                .green.opacity(0.1)
        case .converting:
                .blue.opacity(0.1)
        case .failed:
                .yellow.opacity(0.1)
        case .idle:
                .blue.opacity(0.1)
        }
    }
    
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
        HStack {
            Button(action: {
                fileConverterViewModel.chooseFileFromFinder()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.gray.opacity(0.1))
                        .stroke(.gray.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [16, 10]))
                        .frame(height: 100)
                    
                    VStack(alignment: .center, spacing: 3) {
                        if let item = fileConverterViewModel.item {
                            Image(nsImage: item.icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                            
                            MarqueeText(
                                .constant(item.displayName),
                                font: .system(size: 12, weight: .medium),
                                nsFont: .headline,
                                textColor: .white.opacity(0.8),
                                backgroundColor: .clear,
                                minDuration: 1.0,
                                frameWidth: 75.scaled(by: scale),
                                shortTextAlignment: .center
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
            .disabled(fileConverterViewModel.isConverting)
            .buttonStyle(.plain)
            
            Image(systemName: "arrow.right")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            
            Menu {
                ForEach(fileConverterViewModel.availableFormats) { format in
                    Button(format.title) {
                        fileConverterViewModel.selectedFormat = format
                    }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(fillColor)
                        .stroke (
                            strokeColor,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [16, 10])
                        )
                        .frame(height: 100)
                    
                    VStack(spacing: 4) {
                        Text(fileConverterViewModel.selectedFormat.title)
                            .lineLimit(1)
                            .font(.system(size: 17, weight: .bold))
                        
                        Text(verbatim: "Format")
                            .lineLimit(1)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.58))
                    }
                    
                    switch fileConverterViewModel.status {
                    case .idle:
                        EmptyView()
                        
                    case .converted:
                        ZStack {
                            Circle()
                                .fill(.green)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.white)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .offset(x: -60, y: 45)
                        
                    case .failed:
                        ZStack {
                            Circle()
                                .fill(.yellow)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "exclamationmark")
                                .foregroundStyle(Color.black)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .offset(x: -60, y: 45)
                        
                    case .converting:
                        EmptyView()
                    }
                }
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .disabled(fileConverterViewModel.isConverting)
        }
    }
    
    @ViewBuilder
    private var actionRow: some View {
        HStack {
            if !fileConverterViewModel.isConverting {
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
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    fileConverterViewModel.convert(
                        options: FileConverterConversionOptions(settings: mediaSettings)
                    )
                }
                onRequestCollapse()
            }) {
                Text(verbatim: fileConverterViewModel.isConverting ? "Converting..." : "Convert to \(fileConverterViewModel.selectedFormat.title)")
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .blue.opacity(0.2)))
            .disabled(fileConverterViewModel.isConverting)
        }
    }
}
