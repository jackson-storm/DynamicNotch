//
//  OnboardingNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/7/26.
//

import SwiftUI

struct OnboardingNotchView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @Environment(\.locale) private var locale
    
    let step: OnboardingSteps
    let onStepChange: (OnboardingSteps) -> Void
    let onFinish: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            stepContent
            buttons
            Spacer()
        }
        .padding(.top, isNotchlessScreen ? 10 : 30)
        .padding(.horizontal, isNotchlessScreen ? 15 : 35)
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .first:
            OnboardingNotchFirstStepView()
        case .second:
            OnboardingNotchSecondStepView()
        case .third:
            OnboardingNotchThirdStepView()
        case .fourth:
            OnboardingNotchFourthStepView()
        }
    }
    
    @ViewBuilder
    private var buttons: some View {
        switch step {
        case .first:
            HStack {
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Text(locale.dn("notch.onboarding.exit", fallback: "Exit"))
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .red.opacity(0.25)))
                
                Spacer()
                
                Button(action: {
                    onStepChange(.second)
                }) {
                    Text(locale.dn("notch.onboarding.continue", fallback: "Continue"))
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .blue.opacity(0.25)))
            }
            
        case .second:
            HStack {
                Button(action: {
                    guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") else {
                        return
                    }
                    openURL(url)
                    
                }) {
                    Text(locale.dn("notch.onboarding.openSettings", fallback: "Open Settings"))
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .gray.opacity(0.25)))
                
                Spacer()
                
                Button(action: {
                    onStepChange(.third)
                }) {
                    Text(locale.dn("notch.onboarding.continue", fallback: "Continue"))
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .blue.opacity(0.25)))
            }
            
        case .third:
            HStack {
                Button(action: {
                    guard let url = URL(string: "https://github.com/jackson-storm/DynamicNotch") else {
                        return
                    }
                    openURL(url)
                }) {
                    Text(locale.dn("notch.onboarding.openGitHub", fallback: "Open GitHub"))
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .gray.opacity(0.25)))
                
                Spacer()
                
                Button(action: {
                    onStepChange(.fourth)
                }) {
                    Text(locale.dn("notch.onboarding.continue", fallback: "Continue"))
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .blue.opacity(0.25)))
            }

        case .fourth:
            HStack {
                Button(action: {
                    guard let url = URL(string: "https://t.me/Dynamic_Notch") else {
                        return
                    }
                    openURL(url)
                    onFinish()
                }) {
                    Text(locale.dn("notch.onboarding.openTelegram", fallback: "Open Telegram"))
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .gray.opacity(0.25)))

                Spacer()

                Button(action: {
                    onFinish()
                }) {
                    Text(locale.dn("notch.onboarding.finish", fallback: "Finish"))
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .blue.opacity(0.25)))
            }
        }
    }
}
