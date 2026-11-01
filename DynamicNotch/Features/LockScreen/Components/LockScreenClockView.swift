//
//  ExpandedLockScreenClockView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/13/26.
//

import SwiftUI

struct LockScreenClockView: View {
    @Environment(\.locale) private var locale
    let date: Date
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 58) {
            Spacer()
            
            Text(timeString)
                .font(.system(size: 38, weight: .heavy, design: .default))
                .foregroundStyle(.white)
            
            Text(dateString)
                .font(.system(size: 38, weight: .semibold, design: .default))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: true, vertical: false)
            
            Spacer()
        }
        .frame(width: width, height: height, alignment: .leading)
        .shadow(color: .black.opacity(0.28), radius: 10, x: 0, y: 4)
    }

    private var timeString: String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    private var dateString: String {
        date.formatted(
            .dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(locale)
        ).localizedCapitalizedFirstLetter
    }
}

private extension String {
    var localizedCapitalizedFirstLetter: String {
        guard let first else { return self }

        return String(first).localizedUppercase + dropFirst()
    }
}
