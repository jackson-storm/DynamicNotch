//
//  TrayExpandedActiveNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/26/26.
//

import SwiftUI

struct TrayExpandedActiveNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var fileTrayViewModel: FileTrayViewModel
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                header
                Spacer()
            }
            .padding(.top, 10.scaled(by: scale))
            .padding(.horizontal, 42)
            
            VStack(alignment: .leading) {
                Spacer()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(fileTrayViewModel.items) { item in
                            TrayExpandedItemView(item: item) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    fileTrayViewModel.remove(item)
                                }
                            }
                            .transition(
                                .blurAndFade
                                    .combined(with: .scale)
                                    .combined(with: .opacity)
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.02),
                            .init(color: .black, location: 0.98),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 14)
        }
    }
    
    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: "tray.full.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            
            AnimatedLevelText(level: fileTrayViewModel.count, fontSize: 14)
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    fileTrayViewModel.clear()
                }
            } label: {
                Text("Clear All")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .buttonStyle(.plain)
            .disabled(fileTrayViewModel.items.isEmpty)
            .opacity(fileTrayViewModel.items.isEmpty ? 0 : 1)
        }
    }
}

private struct TrayExpandedItemView: View {
    let item: FileTrayItem
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 7) {
            ZStack(alignment: .topTrailing) {
                Image(nsImage: item.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .padding(.top, 4)
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.58))
                        .background(Circle().fill(.black.opacity(0.28)))
                }
                .buttonStyle(.plain)
                .offset(x: 15)
            }
            .frame(width: 55, height: 47)
            
            Text(item.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 72, height: 28)
        }
        .frame(width: 84, height: 94)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.10))
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onDrag {
            item.itemProvider
        }
        .help(item.url.path)
    }
}
