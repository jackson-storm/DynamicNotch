//
//  OnboardingNotchFourthStepView.swift
//  DynamicNotch
//
//  Created by OpenAI on 4/22/26.
//

import SwiftUI

struct OnboardingNotchFourthStepView: View {
    @State private var contentAppear = false

    var body: some View {
        HStack {
            AnimateImage(name: "telegram")
                .frame(width: 84, height: 84)
                .scaleEffect(1.1)
                .shadow(color: .blue, radius: 30)
                .id(contentAppear)

            VStack(alignment: .leading, spacing: 5) {
                Text(verbatim: "Telegram channel")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(verbatim: "Join the Telegram channel to stay up-to-date with new updates.")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(3)
                    .padding(.trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                contentAppear = true
            }
        }
    }
}
