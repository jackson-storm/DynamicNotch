import SwiftUI
import Combine
internal import AppKit

typealias NotchScreenMetrics = (width: CGFloat, topInset: CGFloat)

@MainActor
final class NotchViewModel: ObservableObject {
    @Published private(set) var notchModel = NotchModel()
    @Published var showNotch = false
    @Published var isPressed = false
    @Published private(set) var swipeStretchProgress: CGFloat = 0
    @Published var cachedStrokeColor: Color = .clear

    private let settings: NotchSettingsProviding
    private let engine: NotchEngine
    private let screenMetricsProvider: (NotchDisplayLocation) -> NotchScreenMetrics?
    private var cancellables = Set<AnyCancellable>()

    var animations: NotchAnimations {
        engine.animations
    }

    var canExpandActiveLiveActivity: Bool {
        engine.canExpandActiveLiveActivity
    }

    var canRestoreDismissedContent: Bool {
        engine.canRestoreDismissedContent
    }

    var interactiveNotchSize: CGSize {
        let baseSize = notchModel.size
        let progress = easedSwipeStretchProgress

        return CGSize(
            width: baseSize.width,
            height: baseSize.height + (10 * progress)
        )
    }

    var interactiveCornerRadius: (top: CGFloat, bottom: CGFloat) {
        let baseCornerRadius = notchModel.cornerRadius
        let progress = easedSwipeStretchProgress

        return (
            top: baseCornerRadius.top,
            bottom: baseCornerRadius.bottom + (4 * progress)
        )
    }
    
    
    init(
        settings: NotchSettingsProviding,
        animations: NotchAnimations? = nil,
        hideDelay: TimeInterval = 0.3,
        queueDelay: TimeInterval = 0.3,
        engine: NotchEngine? = nil,
        screenMetricsProvider: ((NotchDisplayLocation) -> NotchScreenMetrics?)? = nil
    ) {
        self.settings = settings
        self.engine = engine ?? NotchEngine(
            animations: {
                animations ?? .preset(settings.notchAnimationPreset)
            },
            hideDelay: hideDelay,
            queueDelay: queueDelay
        )
        self.screenMetricsProvider = screenMetricsProvider ?? { location in
            NSScreen.metrics(for: location)
        }
        bindEngine()
        updateDimensions()
    }

    func updateDimensions() {
        guard let screenMetrics = screenMetricsProvider(settings.displayLocation) else {
            return
        }
        
        let screenWidth = screenMetrics.width
        let topInset = screenMetrics.topInset
        let baseScreenWidth: CGFloat = 1440.0
        let scale = max(0.35, screenWidth / baseScreenWidth)
        
        let widthOffset = CGFloat(settings.notchWidth)
        let heightOffset = CGFloat(settings.notchHeight)
        
        if topInset > 0 {
            engine.updateBaseGeometry(
                width: (190 * scale) + widthOffset,
                height: topInset + heightOffset,
                scale: scale
            )
        } else {
            engine.updateBaseGeometry(
                width: (190 * scale) + widthOffset,
                height: (25 * scale) + heightOffset,
                scale: scale
            )
        }
    }

    func send(_ notchState: NotchState) {
        engine.send(notchState)
    }

    func hideTemporaryNotification() {
        engine.hideTemporaryNotification()
    }

    func dismissActiveContent() {
        engine.dismissActiveContent()
    }

    func restoreDismissedContent() {
        engine.restoreDismissedContent()
    }

    func updateSwipeStretch(progress: CGFloat) {
        swipeStretchProgress = min(max(progress, 0), 1)
    }

    func resetSwipeStretch() {
        guard swipeStretchProgress > 0 else { return }

        withAnimation(animations.stretchReset) {
            swipeStretchProgress = 0
        }
    }

    func handleActiveContentTap() {
        engine.handleActiveContentTap()
    }

    func handleOutsideClick() {
        engine.handleOutsideClick()
    }

    func handleStrokeVisibility() {
        engine.handleStrokeVisibility()
    }

    private var easedSwipeStretchProgress: CGFloat {
        1 - pow(1 - swipeStretchProgress, 2)
    }

    func contentTransition(offsetX: CGFloat, offsetY: CGFloat) -> AnyTransition {
        .blurAndFade
            .animation(animations.contentTransition)
            .combined(with: .scale)
            .combined(with: .offset(x: offsetX, y: offsetY))
    }

    private func bindEngine() {
        notchModel = engine.notchModel
        showNotch = engine.showNotch
        cachedStrokeColor = engine.cachedStrokeColor

        engine.$notchModel
            .sink { [weak self] in
                self?.notchModel = $0
            }
            .store(in: &cancellables)

        engine.$showNotch
            .sink { [weak self] in
                self?.showNotch = $0
            }
            .store(in: &cancellables)

        engine.$cachedStrokeColor
            .sink { [weak self] in
                self?.cachedStrokeColor = $0
            }
            .store(in: &cancellables)
    }
}
