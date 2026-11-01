import SwiftUI

struct TimerDetachedActivityView: View {
    let source: TimerSource

    var body: some View {
        switch source {
        case .system(let model): Countdown(source: source, model: model)
        case .local(let model): Countdown(source: source, model: model)
        }
    }

    private struct Countdown<Model: ObservableObject>: View {
        let source: TimerSource
        @ObservedObject var model: Model

        var body: some View {
            TimelineView(.periodic(from: .now, by: source.isPaused ? 30 : 1)) { context in
                Text(source.formattedTime(at: context.date))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.orange)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .padding(.horizontal, 3)
                    .accessibilityLabel(Text("settings.homePage.pages.timer.title"))
                    .accessibilityValue(Text(source.formattedTime(at: context.date)))
            }
        }
    }
}
