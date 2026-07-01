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
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            }
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
                        .foregroundColor(color(for: viewModel.cpuUsage))
                }
                Divider()
                
                Spacer()
                
                SleekMiniGraphView(history: viewModel.cpuHistory, color: color(for: viewModel.cpuUsage))
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
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            }
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
                            .foregroundColor(color(for: viewModel.memoryUsagePercent))
                        
                        Text(String(format: "%.1f / %.1f GB", viewModel.memoryUsedGB, viewModel.memoryTotalGB))
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                Divider()
                
                Spacer()
                
                SleekMiniGraphView(history: viewModel.memoryHistory, color: color(for: viewModel.memoryUsagePercent))
            }
            .frame(maxWidth: .infinity, maxHeight: 75)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }
    
    private func color(for usage: Double) -> Color {
        if usage < 40.0 {
            return .green
        } else if usage < 75.0 {
            return .orange
        } else {
            return .red
        }
    }
}
