//
//  OnboardingNotchThirdStepView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/7/26.
//

import SwiftUI

struct OnboardingNotchThirdStepView: View {
    @State private var imageAppear = false

    var body: some View {
        HStack {
            AnimateImage(name: "star")
                .frame(width: 84, height: 84)
                .scaleEffect(1.3)
                .shadow(color: .yellow, radius: 30)
                .id(imageAppear)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Support this app")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("Please give it a star on GitHub – it will really help with promotion.")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(3)
                    .padding(.trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                imageAppear = true
            }
        }
    }
}

