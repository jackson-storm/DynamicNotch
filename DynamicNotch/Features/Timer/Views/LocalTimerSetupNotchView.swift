//
//  LocalTimerSetupNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/20/26.
//

internal import AppKit
import SwiftUI

struct LocalTimerSetupNotchView: View {
    @ObservedObject var localTimerViewModel: LocalTimerViewModel
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    @State private var selectedMinutes: Int = 15
    @State private var dragOffset: CGFloat = 0
    @State private var dragStartMinutes: Int = 15

    private let tickSpacing: CGFloat = 9.0
    private let maxMinutes: Int = 120

    init(localTimerViewModel: LocalTimerViewModel) {
        self.localTimerViewModel = localTimerViewModel
        let initialMinutes = localTimerViewModel.totalTime > 0
            ? max(1, Int(localTimerViewModel.totalTime / 60))
            : 15
        self._selectedMinutes = State(initialValue: initialMinutes)
        self._dragStartMinutes = State(initialValue: initialMinutes)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            rulerSection
            bottomControls
                .padding(.trailing, 4)
        }
        .padding(.horizontal, isDynamicIsland ? 8 : 8)
        .padding(.bottom, isDynamicIsland ? 8 : 5)
    }

    private var rulerSection: some View {
        GeometryReader { geometry in
            let containerWidth = geometry.size.width
            let centerOffset = containerWidth / 2

            VStack(spacing: 4) {
                ZStack(alignment: .leading) {
                    rulerTicks
                        .offset(x: centerOffset - ((CGFloat(dragStartMinutes) + 0.5) * tickSpacing) + dragOffset)
                }
                .frame(width: containerWidth, height: 60, alignment: .leading)
                .clipped()
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black, location: 0.20),
                            .init(color: .black, location: 0.80),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                Image(systemName: "triangle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
            }
            .frame(width: containerWidth, height: 50)
            .contentShape(Rectangle())
            .highPriorityGesture(dragGesture)
            .onTapGesture { location in
                let clickedOffset = location.x - centerOffset
                let deltaMinutes = Int(round(clickedOffset / tickSpacing))
                let target = min(max(1, selectedMinutes + deltaMinutes), maxMinutes)
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    selectedMinutes = target
                    dragStartMinutes = target
                    dragOffset = 0
                }
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
            }
        }
        .frame(height: 60, alignment: .bottom)
    }

    private var rulerTicks: some View {
        HStack(spacing: 0) {
            ForEach(0...maxMinutes, id: \.self) { minute in
                let isBeforeOrAtArrow = minute <= selectedMinutes
                VStack(spacing: 4) {
                    if minute % 5 == 0 {
                        Text("\(minute)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(isBeforeOrAtArrow ? Color.orange : Color.orange.opacity(0.45))
                            .lineLimit(1)
                            .fixedSize()
                            .frame(height: 16)
                    } else {
                        Color.clear
                            .frame(height: 16)
                    }
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isBeforeOrAtArrow ? Color.orange : Color.orange.opacity(0.35))
                        .frame(width: 3, height: 35)
                }
                .frame(width: tickSpacing, height: 50)
            }
        }
    }

    private var bottomControls: some View {
        HStack {
            actionButton
            Spacer()
            timeDisplay
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch localTimerViewModel.state {
        case .running:
            Button(action: stopTimer) {
                Text("Stop")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.red)
            }
            .buttonStyle(PrimaryButtonStyle(width: 100, height: 40, backgroundColor: .red.opacity(0.2)))

        case .paused:
            Button(action: resumeTimer) {
                Text("Resume")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.green)
            }
            .buttonStyle(PrimaryButtonStyle(width: 100, height: 40, backgroundColor: .green.opacity(0.2)))

        case .stopped:
            Button(action: startTimer) {
                Text("Start Timer")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.orange)
            }
            .buttonStyle(PrimaryButtonStyle(width: 120, height: 40, backgroundColor: .orange.opacity(0.15)))
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                dragOffset = value.translation.width
                let continuousMinute = Double(dragStartMinutes) - Double(value.translation.width / tickSpacing)
                let clamped = min(max(1, Int(round(continuousMinute))), maxMinutes)
                if clamped != selectedMinutes {
                    selectedMinutes = clamped
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                }
            }
            .onEnded { value in
                let velocity = value.velocity.width
                let projectedTranslation = value.translation.width + (velocity * 0.04)
                let continuousMinute = Double(dragStartMinutes) - Double(projectedTranslation / tickSpacing)
                let targetMinute = min(max(1, Int(round(continuousMinute))), maxMinutes)

                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    selectedMinutes = targetMinute
                    dragStartMinutes = targetMinute
                    dragOffset = 0
                }
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
            }
    }

    private var timeDisplay: some View {
        Text(displayTimeString)
            .font(.system(size: 34, weight: .light, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Color.orange)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private var displayTimeString: String {
        if localTimerViewModel.state == .running || localTimerViewModel.state == .paused {
            return localTimerViewModel.formattedRemainingTime
        }

        let hours = selectedMinutes / 60
        let mins = selectedMinutes % 60

        if hours > 0 {
            return String(format: "%d:%02d:00", hours, mins)
        } else {
            return String(format: "%d:%02d", mins, 0)
        }
    }

    private func startTimer() {
        guard selectedMinutes > 0 else { return }
        let h = selectedMinutes / 60
        let m = selectedMinutes % 60
        localTimerViewModel.start(hours: h, minutes: m, seconds: 0)
    }

    private func stopTimer() {
        localTimerViewModel.stop()
    }

    private func resumeTimer() {
        localTimerViewModel.resume()
    }
}
