//
//  OnboardingNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/7/26.
//

import SwiftUI

struct OnboardingNotchView: View {
    @Environment(\.openURL) private var openURL
    
    let step: OnboardingSteps
    let onStepChange: (OnboardingSteps) -> Void
    let onFinish: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            stepContent
            buttons
        }
        .animation(.spring(duration: 0.4), value: step)
        .padding(.horizontal, 35)
        .padding(.bottom, 10)
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
                    Text(verbatim: "Exit")
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .red.opacity(0.2)))
                
                Spacer()
                
                Button(action: {
                    onStepChange(.second)
                }) {
                    Text(verbatim: "Continue")
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .blue.opacity(0.2)))
            }
            
        case .second:
            HStack {
                Button(action: {
                    guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") else {
                        return
                    }
                    openURL(url)
                    
                }) {
                    Text(verbatim: "Open Settings")
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .gray.opacity(0.2)))
                
                Spacer()
                
                Button(action: {
                    onStepChange(.third)
                }) {
                    Text(verbatim: "Continue")
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .blue.opacity(0.2)))
            }
            
        case .third:
            HStack {
                Button(action: {
                    guard let url = URL(string: "https://github.com/jackson-storm/DynamicNotch") else {
                        return
                    }
                    openURL(url)
                }) {
                    Text(verbatim: "Open GitHub")
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .gray.opacity(0.2)))
                
                Spacer()
                
                Button(action: {
                    onStepChange(.fourth)
                }) {
                    Text(verbatim: "Continue")
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .blue.opacity(0.2)))
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
                    Text(verbatim: "Open Telegram")
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .gray.opacity(0.2)))

                Spacer()

                Button(action: {
                    onFinish()
                }) {
                    Text(verbatim: "Finish")
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .blue.opacity(0.2)))
            }
        }
    }
}
