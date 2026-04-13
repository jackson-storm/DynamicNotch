//
//  OnboardingNotchSecondStepView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/7/26.
//

import SwiftUI

struct OnboardingNotchSecondStepView: View {
    @State private var imageAppear = false

    var body: some View {
        HStack {
            AnimateImage(name: "confirm")
                .frame(width: 84, height: 84)
                .scaleEffect(1.1)
                .shadow(color: .green, radius: 30)
                .id(imageAppear)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(verbatim: "Confirm all permissions")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(verbatim: "You need to make sure that the application has been granted permission.")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(3)
                    .padding(.trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                imageAppear = true
            }
        }
    }
}
