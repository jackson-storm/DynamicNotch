//
//  OnboardingView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/20/26.
//

import SwiftUI

struct OnboardingNotchView: View {
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
