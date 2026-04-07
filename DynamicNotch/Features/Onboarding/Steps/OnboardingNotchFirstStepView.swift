//
//  OnboardingNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/7/26.
//

import SwiftUI

struct OnboardingNotchFirstStepView: View {
    @State private var imageAppear = false
    
    var body: some View {
        ZStack {
            AnimateImage(name: "welcome")
                .frame(width: 180, height: 60)
                .id(imageAppear)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                imageAppear = true
            }
        }
    }
}
