import SwiftUI
internal import AppKit

struct LightweightNowPlayingEqualizerView: NSViewRepresentable {
    let isPlaying: Bool
    let color: NSColor
    let barHeight: CGFloat
    let barWidth: CGFloat

    init(isPlaying: Bool, color: NSColor, barHeight: CGFloat = 16, barWidth: CGFloat = 2) {
        self.isPlaying = isPlaying
        self.color = color
        self.barHeight = barHeight
        self.barWidth = barWidth
    }

    func makeNSView(context: Context) -> LightweightNowPlayingEqualizerNSView {
        let view = LightweightNowPlayingEqualizerNSView()
        view.setBarHeight(barHeight)
        view.setBarWidth(barWidth)
        view.setColor(color)
        view.setPlaying(isPlaying)
        return view
    }

    func updateNSView(_ nsView: LightweightNowPlayingEqualizerNSView, context: Context) {
        nsView.setBarHeight(barHeight)
        nsView.setBarWidth(barWidth)
        nsView.setColor(color)
        nsView.setPlaying(isPlaying)
    }

    static func dismantleNSView(_ nsView: LightweightNowPlayingEqualizerNSView, coordinator: ()) {
        nsView.stop()
    }
}

final class LightweightNowPlayingEqualizerNSView: NSView {
    private enum Metrics {
        static let barCount = 5
        static let defaultBarWidth: CGFloat = 2
        static let barSpacing: CGFloat = 2
        static let defaultHeight: CGFloat = 16
        static let minimumScale: CGFloat = 0.32
        static let animationDuration: TimeInterval = 0.3
        static let timerInterval: TimeInterval = 0.3
    }

    private var barLayers: [CALayer] = []
    private var barScales: [CGFloat] = []
    private var animationTimer: Timer?
    private var isPlaying = false
    private var barColor = NSColor.white
    private var barHeight = Metrics.defaultHeight
    private var barWidth = Metrics.defaultBarWidth
    private var windowObservers: [NSObjectProtocol] = []

    override var intrinsicContentSize: NSSize {
        NSSize(
            width: CGFloat(Metrics.barCount) * barWidth +
                CGFloat(Metrics.barCount - 1) * Metrics.barSpacing,
            height: barHeight
        )
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        removeWindowObservers()
        stop()
    }

    override func layout() {
        super.layout()
        layoutBars()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureWindowObservers()
        syncAnimationState()
    }

    func setPlaying(_ playing: Bool) {
        guard isPlaying != playing else { return }

        isPlaying = playing
        syncAnimationState()
    }

    func setColor(_ color: NSColor) {
        guard !barColor.isEqual(color) else { return }

        barColor = color
        barLayers.forEach { $0.backgroundColor = color.cgColor }
    }

    func setBarHeight(_ height: CGFloat) {
        let resolvedHeight = max(height, barWidth)
        guard abs(barHeight - resolvedHeight) > 0.001 else { return }

        barHeight = resolvedHeight
        invalidateIntrinsicContentSize()
        layoutBars()

        if !isPlaying {
            resetBars()
        }
    }

    func setBarWidth(_ width: CGFloat) {
        let resolvedWidth = max(width, 1)
        guard abs(barWidth - resolvedWidth) > 0.001 else { return }

        barWidth = resolvedWidth
        barLayers.forEach { $0.cornerRadius = resolvedWidth / 2 }
        invalidateIntrinsicContentSize()
        layoutBars()

        if !isPlaying {
            resetBars()
        }
    }

    func stop() {
        animationTimer?.invalidate()
        animationTimer = nil
        resetBars()
    }
}

private extension LightweightNowPlayingEqualizerNSView {
    func setup() {
        wantsLayer = true
        layer?.masksToBounds = false
        createBars()
    }

    func createBars() {
        guard barLayers.isEmpty else { return }

        barScales = Array(repeating: pausedScale, count: Metrics.barCount)

        for _ in 0..<Metrics.barCount {
            let barLayer = CALayer()
            barLayer.backgroundColor = barColor.cgColor
            barLayer.cornerRadius = barWidth / 2
            barLayer.masksToBounds = true
            barLayer.allowsGroupOpacity = false
            barLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            barLayer.transform = CATransform3DMakeScale(1, pausedScale, 1)
            layer?.addSublayer(barLayer)
            barLayers.append(barLayer)
        }

        layoutBars()
    }

    func layoutBars() {
        guard !barLayers.isEmpty else { return }

        let totalWidth = intrinsicContentSize.width
        let originX = max((bounds.width - totalWidth) / 2, 0)
        let centerY = bounds.midY

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        for (index, barLayer) in barLayers.enumerated() {
            let x = originX + CGFloat(index) * (barWidth + Metrics.barSpacing)
            barLayer.bounds = CGRect(
                x: 0,
                y: 0,
                width: barWidth,
                height: barHeight
            )
            barLayer.position = CGPoint(x: x + barWidth / 2, y: centerY)
            barLayer.transform = CATransform3DMakeScale(1, barScales[index], 1)
        }

        CATransaction.commit()
    }

    func syncAnimationState() {
        guard isInVisibleWindow, isPlaying else {
            stop()
            return
        }

        start()
    }

    func start() {
        guard animationTimer == nil else { return }

        animateBars()

        let timer = Timer(timeInterval: Metrics.timerInterval, repeats: true) { [weak self] _ in
            self?.animateBars()
        }

        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
    }

    func resetBars() {
        let scale = pausedScale

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        for (index, barLayer) in barLayers.enumerated() {
            barLayer.removeAnimation(forKey: "dynamicNotch.scaleY")
            barScales[index] = scale
            barLayer.transform = CATransform3DMakeScale(1, scale, 1)
        }

        CATransaction.commit()
    }

    func animateBars() {
        guard isPlaying, isInVisibleWindow else {
            stop()
            return
        }

        for (index, barLayer) in barLayers.enumerated() {
            let currentScale = barScales[index]
            let targetScale = CGFloat.random(in: minimumPlayingScale...1)
            barScales[index] = targetScale

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            barLayer.transform = CATransform3DMakeScale(1, targetScale, 1)
            CATransaction.commit()

            let animation = CABasicAnimation(keyPath: "transform.scale.y")
            animation.fromValue = currentScale
            animation.toValue = targetScale
            animation.duration = Metrics.animationDuration
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            if #available(macOS 13.0, *) {
                animation.preferredFrameRateRange = CAFrameRateRange(
                    minimum: 24,
                    maximum: 24,
                    preferred: 24
                )
            }

            barLayer.add(animation, forKey: "dynamicNotch.scaleY")
        }
    }

    var pausedScale: CGFloat {
        min(max(barWidth / max(barHeight, 1), 0.001), 1)
    }

    var minimumPlayingScale: CGFloat {
        min(max(Metrics.minimumScale, pausedScale), 1)
    }

    var isInVisibleWindow: Bool {
        guard let window, window.isVisible else { return false }
        return window.occlusionState.contains(.visible)
    }

    func configureWindowObservers() {
        removeWindowObservers()

        guard let window else { return }

        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            NSWindow.didChangeOcclusionStateNotification,
            NSWindow.didMiniaturizeNotification,
            NSWindow.didDeminiaturizeNotification,
            NSWindow.willCloseNotification
        ]

        windowObservers = names.map { name in
            center.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                self?.syncAnimationState()
            }
        }
    }

    func removeWindowObservers() {
        let center = NotificationCenter.default
        windowObservers.forEach(center.removeObserver)
        windowObservers.removeAll()
    }
}
