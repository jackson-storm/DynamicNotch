//
//  OnboardingView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/20/26.
//

import SwiftUI

struct OnboardingNotchContent : NotchContentProtocol {
    let id = "onboarding"
    let notchEventCoordinator: NotchEventCoordinator
    
    var offsetYTransition: CGFloat { -60 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 70, height: baseHeight + 120)
    }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 36)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(OnboardingNotchView(notchEventCoordinator: notchEventCoordinator))
    }
}

private struct OnboardingNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var notchEventCoordinator: NotchEventCoordinator
    @State private var imageAppear = false
    
    var body: some View {
        VStack {
            Spacer()
            
            AnimateImage(name: "welcome")
                .frame(width: 180, height: 80)
                .id(imageAppear)
                        
            buttons
        }
        .font(.system(size: 14))
        .padding(.horizontal, 40)
        .padding(.bottom, 10)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                imageAppear = true
            }
        }
    }
    
    @ViewBuilder
    var buttons: some View {
        HStack {
            Button(action: { NSApp.terminate(nil) }) {
                Text("Exit")
            }
            .buttonStyle(PrimaryButtonStyle(height: 30, backgroundColor: .red))
            
            Spacer()
            
            Button(action: { notchEventCoordinator.finishOnboarding() }) {
                Text("Start")
            }
            .buttonStyle(PrimaryButtonStyle(height: 30))
        }
        .foregroundStyle(.white)
    }
}
