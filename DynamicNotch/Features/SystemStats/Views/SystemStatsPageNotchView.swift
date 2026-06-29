//
//  SystemStatsPageNotchView.swift
//  DynamicNotch
//
//  Created by Antigravity on 6/29/26.
//

import SwiftUI
internal import AppKit

struct SystemStatsPageNotchView: View {
    @StateObject private var viewModel = SystemStatsViewModel()
    let notchViewModel: NotchViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            
            HStack(spacing: 8) {
                cpuView
                ramView
            }
        }
        .padding(.horizontal, 5)
        .padding(.bottom, 3)
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
    
    @ViewBuilder
    private var cpuView: some View {
        Button(action: {
            NSWorkspace.shared.launchApplication("Activity Monitor")
            notchViewModel.dismissActiveContent()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(verbatim: "CPU")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(String(format: "%.1f%%", viewModel.cpuUsage))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                }
                Divider()
                
                Spacer()
                
                SleekMiniGraphView(history: viewModel.cpuHistory, color: .blue)
            }
            .frame(maxWidth: .infinity, maxHeight: 75)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var ramView: some View {
        Button(action: {
            NSWorkspace.shared.launchApplication("Activity Monitor")
            notchViewModel.dismissActiveContent()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "memorychip")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(verbatim: "RAM")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(String(format: "%.1f%%", viewModel.memoryUsagePercent))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                        
                        Text(String(format: "%.1f / %.1f GB", viewModel.memoryUsedGB, viewModel.memoryTotalGB))
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                Divider()
                
                Spacer()
                
                SleekMiniGraphView(history: viewModel.memoryHistory, color: .green)
            }
            .frame(maxWidth: .infinity, maxHeight: 75)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }
}

struct SleekMiniGraphView: View {
    var history: [Double]
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            let points = normalizedPoints(in: geometry.size)
            
            ZStack {
                if points.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geometry.size.height))
                        for pt in points {
                            path.addLine(to: pt)
                        }
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.25), color.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                if points.count > 1 {
                    Path { path in
                        path.move(to: points[0])
                        for pt in points.dropFirst() {
                            path.addLine(to: pt)
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                    )
                }
            }
        }
        .frame(height: 28)
    }
    
    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard history.count > 1 else { return [] }
        let stepX = size.width / CGFloat(history.count - 1)
        
        let maxVal = max(history.max() ?? 0.0, 20.0)
        
        return history.enumerated().map { index, val in
            let x = CGFloat(index) * stepX
            let normalizedY = CGFloat(val / maxVal)
            let y = size.height - (normalizedY * size.height * 0.8) - (size.height * 0.1)
            return CGPoint(x: x, y: y)
        }
    }
}
