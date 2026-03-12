//
//  SettingsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/14/26.
//

import SwiftUI

enum NotchDisplayLocation: String, CaseIterable {
    case builtIn
    case main
    
    var title: String {
        switch self {
        case .builtIn: return "Show on other display"
        case .main:    return "Show on main screen"
        }
    }
    
    var symbolName: String {
        switch self {
        case .builtIn: return "laptopcomputer"
        case .main:    return "display.2"
        }
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var powerService: PowerService
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel
    
    var body: some View {
        Form {
            systemSection
            notchShapeSection
            animationSection
        }
        .formStyle(.grouped)
        .accessibilityIdentifier("settings.general.root")
    }
    
    @ViewBuilder
    var systemSection: some View {
        Section("System") {
            Toggle("Launch at login", isOn: $generalSettingsViewModel.isLaunchAtLoginEnabled)
                .toggleStyle(CustomToggleStyle())
                .accessibilityIdentifier("settings.general.launchAtLogin")
            
            Toggle("Show menu bar icon", isOn: $generalSettingsViewModel.isMenuBarIconVisible)
                .toggleStyle(CustomToggleStyle())
                .accessibilityIdentifier("settings.general.menuBarIcon")
            
            CustomPicker(
                selection: $generalSettingsViewModel.displayLocation,
                options: Array(NotchDisplayLocation.allCases),
                title: { $0.title },
                symbolName: { $0.symbolName }
            )
            .padding(.top, 4)
            .accessibilityIdentifier("settings.general.displayLocation")
        }
    }
    
    @ViewBuilder
    var notchShapeSection: some View {
        Section("Notch shape") {
            ZStack(alignment: .top) {
                Image("backgroundDark")
                    .resizable()
                    .frame(height: 100)
                    .cornerRadius(10)
                
                NotchShape(topCornerRadius: notchViewModel.notchModel.cornerRadius.top, bottomCornerRadius: notchViewModel.notchModel.cornerRadius.bottom)
                    .fill(.black)
                    .stroke(generalSettingsViewModel.isShowNotchStrokeEnabled ? .green.opacity(0.3) : Color.clear, lineWidth: generalSettingsViewModel.notchStrokeWidth)
                    .overlay(ChargerNotchView(powerService: powerService))
                    .frame(width: 370, height: 38)
            }
            
            Toggle("Show notch stroke ", isOn: $generalSettingsViewModel.isShowNotchStrokeEnabled)
                .toggleStyle(CustomToggleStyle())
                .accessibilityIdentifier("settings.general.showNotchStroke")
            
            TickedSlider(
                title: "Stroke width",
                value: $generalSettingsViewModel.notchStrokeWidth,
                range: 1...3,
                step: 0.5,
                valueFormatter: { "\($0) px" }
            )
            .accessibilityIdentifier("settings.general.notchStrokeWidth")
            
            TickedSlider(
                title: "Notch width",
                value: Binding<Double>(
                    get: { Double(generalSettingsViewModel.notchWidth) },
                    set: { generalSettingsViewModel.notchWidth = Int($0.rounded()) }
                ),
                range: -8...8,
                step: 1,
                valueFormatter: { "\(Int($0)) px" }
            )
            .accessibilityIdentifier("settings.general.notchWidth")
            
            TickedSlider(
                title: "Notch height",
                value: Binding<Double>(
                    get: { Double(generalSettingsViewModel.notchHeight) },
                    set: { generalSettingsViewModel.notchHeight = Int($0.rounded()) }
                ),
                range: -4...4,
                step: 1,
                valueFormatter: { "\(Int($0)) px" }
            )
            .accessibilityIdentifier("settings.general.notchHeight")
        }
    }
    
    @ViewBuilder
    var animationSection: some View {
        
    }
}
