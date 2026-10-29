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
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @Environment(\.locale) private var locale

    @State private var selectedIndex: Int = 20
    @State private var dragOffset: CGFloat = 0
    @State private var dragStartIndex: Int = 20
    @State private var isDragging: Bool = false
    @State private var scrollDirection: Int = 1

    var onClose: (() -> Void)? = nil

    private let tickSpacing: CGFloat = 9.0
    private static let subMinuteCount: Int = 5
    private static let subMinuteStepSeconds: Int = 10
    private static let secondsPerMinute: Int = 60
    private static let maxMinutes: Int = 120
    private static let maxIndex: Int = subMinuteCount + maxMinutes

    init(localTimerViewModel: LocalTimerViewModel, onClose: (() -> Void)? = nil) {
        self.localTimerViewModel = localTimerViewModel
        self.onClose = onClose
        let initialSeconds = localTimerViewModel.totalTime > 0
            ? Int(localTimerViewModel.totalTime)
            : 15 * 60
        let initialIndex = Self.index(forTotalSeconds: initialSeconds)
        self._selectedIndex = State(initialValue: initialIndex)
        self._dragStartIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        VStack {
            Spacer()
            rulerSection
            bottomControls
            Spacer()
        }
        .padding(.top, isNotchlessScreen ? 25 : 35)
        .padding(.horizontal, isNotchlessScreen ? 15 : 45)
    }

    private var rulerSection: some View {
        GeometryReader { geometry in
            let containerWidth = geometry.size.width
            let centerOffset = containerWidth / 2

            VStack(spacing: 4) {
                ZStack(alignment: .leading) {
                    rulerTicks
                        .offset(x: centerOffset - ((CGFloat(dragStartIndex) + 0.5) * tickSpacing) + dragOffset)
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
                    .shadow(color: Color.orange.opacity(isDragging ? 0.8 : 0), radius: 3)
            }
            .frame(width: containerWidth, height: 50)
            .contentShape(Rectangle())
            .highPriorityGesture(dragGesture)
            .onTapGesture { location in
                let clickedOffset = location.x - centerOffset
                let deltaTicks = Int(round(clickedOffset / tickSpacing))
                let target = min(max(1, selectedIndex + deltaTicks), Self.maxIndex)
                scrollDirection = target >= selectedIndex ? 1 : -1
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    selectedIndex = target
                    dragStartIndex = target
                    dragOffset = 0
                }
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
            }
        }
        .frame(height: 60, alignment: .bottom)
    }

    private var rulerTicks: some View {
        HStack(spacing: 0) {
            ForEach(0...Self.maxIndex, id: \.self) { index in
                RulerTickView(
                    index: index,
                    selectedIndex: selectedIndex,
                    isDragging: isDragging,
                    scrollDirection: scrollDirection,
                    label: tickLabel(for: index),
                    tickSpacing: tickSpacing
                )
            }
        }
    }

    private func tickLabel(for index: Int) -> String? {
        if index == 0 {
            return "0"
        } else if index >= Self.subMinuteCount + 1 {
            let minute = index - Self.subMinuteCount
            if minute == 1 || minute % 5 == 0 {
                return "\(minute)"
            }
        }
        return nil
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
                Text(locale.dn("notch.timer.stop", fallback: "Stop"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.red)
            }
            .buttonStyle(PrimaryButtonStyle(width: 100, height: 40, backgroundColor: .red.opacity(0.2)))

        case .paused:
            Button(action: resumeTimer) {
                Text(locale.dn("notch.timer.resume", fallback: "Resume"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.green)
            }
            .buttonStyle(PrimaryButtonStyle(width: 100, height: 40, backgroundColor: .green.opacity(0.2)))

        case .stopped:
            Button(action: startTimer) {
                Text(locale.dn("notch.timer.startTimer", fallback: "Start Timer"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.orange)
            }
            .buttonStyle(PrimaryButtonStyle(width: 120, height: 40, backgroundColor: .orange.opacity(0.15)))
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                }
                dragOffset = value.translation.width
                let continuousIndex = Double(dragStartIndex) - Double(value.translation.width / tickSpacing)
                let clamped = min(max(1, Int(round(continuousIndex))), Self.maxIndex)
                if clamped != selectedIndex {
                    scrollDirection = clamped >= selectedIndex ? 1 : -1
                    selectedIndex = clamped
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                }
            }
            .onEnded { value in
                let velocity = value.velocity.width
                let projectedTranslation = value.translation.width + (velocity * 0.04)
                let continuousIndex = Double(dragStartIndex) - Double(projectedTranslation / tickSpacing)
                let targetIndex = min(max(1, Int(round(continuousIndex))), Self.maxIndex)

                if targetIndex != selectedIndex {
                    scrollDirection = targetIndex >= selectedIndex ? 1 : -1
                }

                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    selectedIndex = targetIndex
                    dragStartIndex = targetIndex
                    dragOffset = 0
                }
                isDragging = false
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
            .padding(.trailing, 4)
    }

    private var displayTimeString: String {
        if localTimerViewModel.state == .running || localTimerViewModel.state == .paused {
            return localTimerViewModel.formattedRemainingTime
        }

        let seconds = totalSeconds(for: selectedIndex)
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
    }

    private func totalSeconds(for index: Int) -> Int {
        if index <= 0 {
            return 0
        } else if index <= Self.subMinuteCount {
            return index * Self.subMinuteStepSeconds
        } else {
            return (index - Self.subMinuteCount) * Self.secondsPerMinute
        }
    }

    private static func index(forTotalSeconds totalSeconds: Int) -> Int {
        if totalSeconds <= 0 {
            return 1
        }
        if totalSeconds < 60 {
            let step = Int(round(Double(totalSeconds) / Double(subMinuteStepSeconds)))
            return min(max(1, step), subMinuteCount)
        } else {
            let minutes = Int(round(Double(totalSeconds) / Double(secondsPerMinute)))
            return min(max(subMinuteCount + 1, minutes + subMinuteCount), maxIndex)
        }
    }

    private func startTimer() {
        let total = totalSeconds(for: selectedIndex)
        guard total > 0 else { return }
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        localTimerViewModel.start(hours: h, minutes: m, seconds: s)
        onClose?()
    }

    private func stopTimer() {
        localTimerViewModel.stop()
    }

    private func resumeTimer() {
        localTimerViewModel.resume()
    }
}

private struct RulerTickView: View {
    let index: Int
    let selectedIndex: Int
    let isDragging: Bool
    let scrollDirection: Int
    let label: String?
    let tickSpacing: CGFloat

    @State private var glow: Double = 0.0
    @State private var fadeTask: Task<Void, Never>? = nil

    private var isBeforeOrAtArrow: Bool {
        index <= selectedIndex
    }

    var body: some View {
        VStack(spacing: 4) {
            if let label = label {
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(isBeforeOrAtArrow ? Color.orange : Color.orange.opacity(0.45))
                    .shadow(color: Color.orange.opacity(glow * 0.9), radius: 4 * glow)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(height: 16)
            } else {
                Color.clear
                    .frame(height: 16)
            }
            RoundedRectangle(cornerRadius: 2)
                .fill(tickColor)
                .shadow(color: Color.orange.opacity(glow * 0.95), radius: 4 * glow, x: 0, y: 0)
                .shadow(color: Color.orange.opacity(glow * 0.6), radius: 8 * glow, x: 0, y: 0)
                .frame(width: 3, height: 35)
        }
        .frame(width: tickSpacing, height: 50)
        .onChange(of: selectedIndex) { oldIndex, newIndex in
            handleIndexChange(oldIndex: oldIndex, newIndex: newIndex)
        }
        .onChange(of: isDragging) { _, dragging in
            if !dragging {
                fadeTask?.cancel()
                withAnimation(.easeOut(duration: 0.55)) {
                    glow = 0.0
                }
            } else {
                checkActiveGlow(currentSelected: selectedIndex)
            }
        }
        .onDisappear {
            fadeTask?.cancel()
        }
    }

    private var tickColor: Color {
        if isBeforeOrAtArrow {
            if glow > 0.01 {
                return Color(
                    red: 1.0,
                    green: min(0.72, 0.58 + 0.14 * glow),
                    blue: 0.0
                )
            } else {
                return Color.orange
            }
        } else {
            if glow > 0.01 {
                let opacity = 0.35 + 0.65 * glow
                return Color(
                    red: 1.0,
                    green: min(0.72, 0.58 + 0.14 * glow),
                    blue: 0.0
                ).opacity(opacity)
            } else {
                return Color.orange.opacity(0.35)
            }
        }
    }

    private func handleIndexChange(oldIndex: Int, newIndex: Int) {
        let diff = newIndex - index
        let inTrail: Bool
        let distance: Int

        if newIndex >= oldIndex {
            inTrail = (diff >= 0 && diff <= 1)
            distance = diff
        } else {
            inTrail = (diff <= 0 && diff >= -1)
            distance = abs(diff)
        }

        if inTrail {
            let targetGlow = 1.0 - (Double(distance) * 0.22)
            glow = max(glow, targetGlow)
            triggerFadeOut()
        }
    }

    private func checkActiveGlow(currentSelected: Int) {
        guard isDragging else { return }
        let diff = currentSelected - index
        if diff >= 0 && diff <= 1 {
            let targetGlow = 1.0 - (Double(diff) * 0.22)
            glow = max(glow, targetGlow)
            triggerFadeOut()
        }
    }

    private func triggerFadeOut() {
        fadeTask?.cancel()
        fadeTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.5)) {
                glow = 0.0
            }
        }
    }
}
