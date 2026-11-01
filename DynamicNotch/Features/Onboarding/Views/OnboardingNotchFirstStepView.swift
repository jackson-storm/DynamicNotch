//
//  OnboardingNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/7/26.
//

import SwiftUI

struct OnboardingNotchFirstStepView: View {
    @Environment(\.locale) private var locale
    @State private var imageAppear = false
    
    var body: some View {
        ZStack {
            if locale.language.languageCode?.identifier == "ru" {
                Text("onboarding.welcome")
                    .font(.system(size: 42, weight: .light, design: .rounded))
                    .foregroundStyle(.blue)
                    .frame(width: 180, height: 60)
                    .opacity(imageAppear ? 1 : 0)
                    .blur(radius: imageAppear ? 0 : 6)
                    .animation(.easeOut(duration: 0.7), value: imageAppear)
            } else {
                AnimateImage(name: "welcome")
                    .frame(width: 180, height: 60)
                    .id(imageAppear)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                imageAppear = true
            }
        }
    }
}
