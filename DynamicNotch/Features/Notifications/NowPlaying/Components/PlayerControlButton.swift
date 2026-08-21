//
//  PlayerControlButton.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct PlayerControlButton: View {
    enum FeedbackStyle {
        case neutral
        case backward
        case playPause
        case forward

        var iconTravel: CGFloat {
            switch self {
            case .neutral, .playPause: 0
            case .backward: -3.5
            case .forward: 3.5
            }
        }

        var iconPeakScale: CGFloat {
            switch self {
            case .playPause: 1.18
            case .neutral, .backward, .forward: 1.11
            }
        }

        var iconRotation: Double {
            switch self {
            case .neutral, .playPause: 0
            case .backward: -7
            case .forward: 7
            }
        }

        var pulseOpacity: Double {
            switch self {
            case .playPause: 0.22
            case .neutral, .backward, .forward: 0.14
            }
        }

        var pulseTint: Color {
            switch self {
            case .playPause:
                return Color.white
            case .neutral, .backward, .forward:
                return Color.white.opacity(0.9)
            }
        }

        var pulseScale: CGFloat {
            switch self {
            case .playPause: 1.34
            case .neutral, .backward, .forward: 1.24
            }
        }
    }

    @Environment(\.notchScale) var scale

    let systemImage: String
    let fontSize: CGFloat
    let width: CGFloat
    let height: CGFloat
    let feedbackStyle: FeedbackStyle
    let action: () -> Void

    @State private var pulseScale: CGFloat = 0.74
    @State private var pulseOpacity: Double = 0
    @State private var iconScale: CGFloat = 1
    @State private var iconOffsetX: CGFloat = 0
    @State private var iconRotation: Double = 0

    init(
        systemImage: String,
        fontSize: CGFloat,
        width: CGFloat,
        height: CGFloat,
        feedbackStyle: FeedbackStyle = .neutral,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.fontSize = fontSize
        self.width = width
        self.height = height
        self.feedbackStyle = feedbackStyle
        self.action = action
    }

    var body: some View {
        Button(action: triggerAction) {
            ZStack {
                RoundedRectangle(cornerRadius: min(width, height) * 0.5, style: .continuous)
                    .fill(feedbackStyle.pulseTint)
                    .opacity(pulseOpacity)
                    .scaleEffect(pulseScale)
                    .blur(radius: 4)

                Image(systemName: systemImage)
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .scaleEffect(iconScale)
                    .offset(x: iconOffsetX)
                    .rotationEffect(.degrees(iconRotation))
                    .contentTransition(.symbolEffect(.replace))
                    .animation(.spring(response: 0.26, dampingFraction: 0.76), value: systemImage)
            }
        }
        .buttonStyle(
            PressedButtonStyle(
                width: width,
                height: height,
                cornerRadius: min(width, height) * 0.5,
                hoverBackground: .white.opacity(0.09)
            )
        )
    }

    private func triggerAction() {
        startFeedback()
        action()
    }

    private func startFeedback() {
        pulseScale = 0.74
        pulseOpacity = feedbackStyle.pulseOpacity
        iconScale = 0.96
        iconOffsetX = 0
        iconRotation = 0

        withAnimation(.easeOut(duration: 0.22)) {
            pulseScale = feedbackStyle.pulseScale
            pulseOpacity = 0
        }

        withAnimation(.spring(response: 0.18, dampingFraction: 0.55)) {
            iconScale = feedbackStyle.iconPeakScale
            iconOffsetX = feedbackStyle.iconTravel
            iconRotation = feedbackStyle.iconRotation
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.74)) {
                iconScale = 1
                iconOffsetX = 0
                iconRotation = 0
            }
        }
    }
}
