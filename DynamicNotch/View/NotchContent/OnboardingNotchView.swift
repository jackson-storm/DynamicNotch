//
//  OnboardingView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/20/26.
//

import SwiftUI

struct OnboardingNotchView: View {
    @ObservedObject var notchEventCoordinator: NotchEventCoordinator
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 3) {
                Text("Dynamic Notch")
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                Text("Customize your Mac to the next level")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            Spacer()
            
            buttons
        }
        .foregroundColor(.white)
        .padding(.horizontal, 41)
        .padding(.top, 30)
        .padding(.bottom, 12)
    }
    
    @ViewBuilder
    var buttons: some View {
        HStack {
            Button(action: { NSApp.terminate(nil) }) {
                Text("Exit")
            }
            .buttonStyle(PrimaryButtonStyle(backgroundColor: .red))
            
            Button(action: { notchEventCoordinator.finishOnboarding() }) {
                Text("Start")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

#Preview {
    ZStack(alignment: .top) {
        NotchShape(topCornerRadius: 28, bottomCornerRadius: 36)
            .fill(.black)
            .stroke(.white.opacity(0.1), lineWidth: 1)
            .overlay(OnboardingNotchView(notchEventCoordinator: NotchEventCoordinator(notchViewModel: NotchViewModel())))
            .frame(width: 296, height: 178)
        
        NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
            .stroke(.red, lineWidth: 1)
            .frame(width: 226, height: 38)
    }
    .frame(width: 350, height: 200, alignment: .top)
}
