internal import AppKit
import SwiftUI
import QuartzCore

struct ScreenshotFlyAnimationView: View {
    let image: NSImage
    let startPoint: CGPoint
    let notchPoint: CGPoint
    let screenSize: CGSize
    let isNotchless: Bool
    let onReachNotch: (@MainActor () -> Void)?
    let onEarlyComplete: @MainActor () -> Void
    let onFinished: @MainActor () -> Void
    
    private let trajectory: ScreenshotFlyTrajectory
    private let baseWidth: CGFloat
    private let baseHeight: CGFloat
    
    @State private var startTime: Date?
    @State private var hasTriggeredReachNotch = false
    @State private var hasTriggeredEarlyComplete = false
    @State private var hasFinished = false
    
    private let duration: Double = 0.44
    private let sliceCount: Int = 36
    private static let shadowBlurRadius: CGFloat = 14
    private static let maxFlightBlurRadius: CGFloat = 14
    private static let glowBlurRadius: CGFloat = 12
    
    init(
        image: NSImage,
        startPoint: CGPoint,
        notchPoint: CGPoint,
        screenSize: CGSize,
        isNotchless: Bool,
        onReachNotch: (@MainActor () -> Void)?,
        onEarlyComplete: @escaping @MainActor () -> Void,
        onFinished: @escaping @MainActor () -> Void
    ) {
        self.image = image
        self.startPoint = startPoint
        self.notchPoint = notchPoint
        self.screenSize = screenSize
        self.isNotchless = isNotchless
        self.onReachNotch = onReachNotch
        self.onEarlyComplete = onEarlyComplete
        self.onFinished = onFinished
        self.trajectory = ScreenshotFlyTrajectory(start: startPoint, notch: notchPoint, screenSize: screenSize)
        let baseWidth = Self.baseWidth(for: screenSize)
        self.baseWidth = baseWidth
        self.baseHeight = baseWidth / Self.clampedAspect(of: image.size)
    }
    
    private static func baseWidth(for screenSize: CGSize) -> CGFloat {
        min(360.0, max(240.0, screenSize.width * 0.24))
    }
    
    private static func clampedAspect(of imgSize: CGSize) -> CGFloat {
        let aspect = (imgSize.width > 0 && imgSize.height > 0) ? (imgSize.width / imgSize.height) : 1.0
        return clampedAspect(aspect)
    }
    
    private static func clampedAspect(_ aspect: CGFloat) -> CGFloat {
        max(0.5, min(2.5, aspect.isFinite && aspect > 0 ? aspect : 1.0))
    }
    
    /// The region of a `screenSize` canvas (top-left origin) that the flight can draw into.
    /// A cubic Bezier lies inside the convex hull of its control points, so their bounding rect
    /// holds every spine point; the margin covers the widest strip, the tallest strip, the bow,
    /// and three blur radii of halo.
    static func flightBounds(start: CGPoint, notch: CGPoint, screenSize: CGSize, imageAspect: CGFloat) -> CGRect {
        let trajectory = ScreenshotFlyTrajectory(start: start, notch: notch, screenSize: screenSize)
        let controlPoints = [trajectory.p0, trajectory.p1, trajectory.p2, trajectory.p3]
        let xs = controlPoints.map(\.x)
        let ys = controlPoints.map(\.y)
        let hull = CGRect(
            x: xs.min() ?? start.x,
            y: ys.min() ?? start.y,
            width: (xs.max() ?? start.x) - (xs.min() ?? start.x),
            height: (ys.max() ?? start.y) - (ys.min() ?? start.y)
        )
        
        let baseWidth = baseWidth(for: screenSize)
        let maxStripHeight = baseWidth / clampedAspect(imageAspect)
        let blurMargin = 3 * max(shadowBlurRadius, maxFlightBlurRadius, glowBlurRadius)
        let bowAllowance = abs(trajectory.deltaX) * 0.045
        let margin = baseWidth / 2 + maxStripHeight + blurMargin + bowAllowance
        
        let screenRect = CGRect(origin: .zero, size: screenSize)
        let bounds = hull.insetBy(dx: -margin, dy: -margin).integral.intersection(screenRect)
        return bounds.isNull ? screenRect : bounds
    }
    
    private func easeFlightProgress(_ t: CGFloat) -> CGFloat {
        if t < 0.40 {
            return 1.4 * t * t
        } else {
            let p = (t - 0.40) / 0.60
            return 0.224 + 0.776 * pow(p, 1.45)
        }
    }
    
    var body: some View {
        TimelineView(.animation) { timelineContext in
            let elapsed = timelineContext.date.timeIntervalSince(startTime ?? timelineContext.date)
            let rawProgress = min(1.0, max(0.0, elapsed / duration))
            let progress = easeFlightProgress(rawProgress)
            
            ZStack(alignment: .top) {
                Canvas { context, size in
                    let scale = max(0.18, 1.0 - 0.75 * progress)
                    let alpha = progress < 0.72 ? 1.0 : max(0.0, 1.0 - (progress - 0.72) / 0.28)
                    let deltaT = max(0.06, 0.18 * (1.0 - 0.65 * progress))
                    let totalHeight = max(10.0, baseHeight * scale)
                    
                    var spinePoints: [CGPoint] = []
                    var tangents: [CGFloat] = []
                    var leftBoundary: [CGPoint] = []
                    var rightBoundary: [CGPoint] = []
                    var sliceWidths: [CGFloat] = []
                    
                    let bowMultiplier: CGFloat = trajectory.isLateral ? (trajectory.deltaX * 0.045 * (1.0 - progress) * sin(progress * .pi)) : 0.0
                    
                    for i in 0..<sliceCount {
                        let v = CGFloat(i) / CGFloat(sliceCount - 1)
                        let t = max(0.001, min(0.999, progress + (0.5 - v) * deltaT))
                        
                        var pt = trajectory.point(at: t)
                        let theta = trajectory.tangentAngle(at: t)
                        let normal = CGPoint(x: -sin(theta), y: cos(theta))
                        
                        if bowMultiplier != 0 {
                            let bow = sin(v * .pi) * bowMultiplier
                            pt.x += normal.x * bow
                            pt.y += normal.y * bow
                        }
                        let taper = 1.0 - (1.0 - v) * (0.42 * progress)
                        let w = baseWidth * scale * taper
                        
                        let halfW = w / 2.0
                        let leftPt = CGPoint(x: pt.x - normal.x * halfW, y: pt.y - normal.y * halfW)
                        let rightPt = CGPoint(x: pt.x + normal.x * halfW, y: pt.y + normal.y * halfW)
                        
                        spinePoints.append(pt)
                        tangents.append(theta)
                        leftBoundary.append(leftPt)
                        rightBoundary.append(rightPt)
                        sliceWidths.append(w)
                    }
                    
                    var boundaryPath = Path()
                    if let firstLeft = leftBoundary.first {
                        boundaryPath.move(to: firstLeft)
                        for pt in leftBoundary.dropFirst() {
                            boundaryPath.addLine(to: pt)
                        }
                        if let lastRight = rightBoundary.last {
                            boundaryPath.addLine(to: lastRight)
                        }
                        for pt in rightBoundary.dropLast().reversed() {
                            boundaryPath.addLine(to: pt)
                        }
                        boundaryPath.closeSubpath()
                    }
                    
                    // A Canvas filter rasterizes the whole current clip, so each blur is clipped
                    // to what it draws plus three radii of halo before the filter is added.
                    var shadowContext = context
                    shadowContext.clip(to: Path(boundaryPath.boundingRect.insetBy(
                        dx: -3 * Self.shadowBlurRadius,
                        dy: -3 * Self.shadowBlurRadius
                    )))
                    shadowContext.addFilter(.blur(radius: Self.shadowBlurRadius))
                    shadowContext.fill(boundaryPath, with: .color(.black.opacity(0.35 * alpha)))
                    
                    let resolvedImage = context.resolve(Image(nsImage: image))
                    let flightBlurRadius: CGFloat = 8.0 + 6.0 * progress
                    
                    var maxStripHeight: CGFloat = 2.5
                    for i in 0..<(sliceCount - 1) {
                        let dist = hypot(spinePoints[i + 1].x - spinePoints[i].x, spinePoints[i + 1].y - spinePoints[i].y)
                        maxStripHeight = max(maxStripHeight, dist * 1.30)
                    }
                    let stripBounds = Self.boundingRect(of: leftBoundary + rightBoundary)
                        .insetBy(dx: -3 * flightBlurRadius, dy: -3 * flightBlurRadius)
                        .insetBy(dx: -(maxStripHeight + baseWidth * scale * 0.01), dy: -(maxStripHeight + baseWidth * scale * 0.01))
                    
                    var imageContext = context
                    imageContext.clip(to: Path(stripBounds))
                    imageContext.drawLayer { layerCtx in
                        layerCtx.addFilter(.blur(radius: flightBlurRadius))
                        
                        for i in 0..<(sliceCount - 1) {
                            let vMid = (CGFloat(i) + 0.5) / CGFloat(sliceCount - 1)
                            let ptMid = CGPoint(
                                x: (spinePoints[i].x + spinePoints[i + 1].x) / 2.0,
                                y: (spinePoints[i].y + spinePoints[i + 1].y) / 2.0
                            )
                            let thetaMid = (tangents[i] + tangents[i + 1]) / 2.0
                            let wMid = (sliceWidths[i] + sliceWidths[i + 1]) / 2.0
                            
                            let dist = hypot(spinePoints[i + 1].x - spinePoints[i].x, spinePoints[i + 1].y - spinePoints[i].y)
                            let stripH = max(2.5, dist * 1.30)
                            
                            var sliceCtx = layerCtx
                            sliceCtx.opacity = alpha
                            sliceCtx.translateBy(x: ptMid.x, y: ptMid.y)
                            sliceCtx.rotate(by: Angle(radians: thetaMid + .pi / 2))
                            
                            let clipRect = CGRect(x: -wMid * 0.51, y: -stripH * 0.55, width: wMid * 1.02, height: stripH * 1.10)
                            sliceCtx.clip(to: Path(clipRect))
                            
                            let imgRect = CGRect(x: -wMid / 2.0, y: -vMid * totalHeight, width: wMid, height: totalHeight)
                            sliceCtx.draw(resolvedImage, in: imgRect)
                        }
                    }
                    
                    if progress > 0.45 && !spinePoints.isEmpty {
                        let glowOpacity = min(0.35, (progress - 0.45) * 0.9) * alpha
                        var glowCtx = context
                        let frontPt = spinePoints[0]
                        let glowRect = CGRect(x: frontPt.x - 45, y: frontPt.y - 15, width: 90, height: 30)
                        glowCtx.clip(to: Path(glowRect.insetBy(dx: -3 * Self.glowBlurRadius, dy: -3 * Self.glowBlurRadius)))
                        glowCtx.addFilter(.blur(radius: Self.glowBlurRadius))
                        glowCtx.fill(Path(ellipseIn: glowRect), with: .color(.white.opacity(glowOpacity)))
                    }
                }
                .onAppear {
                    if startTime == nil {
                        startTime = timelineContext.date
                    }
                }
                .onChange(of: rawProgress) { _, newProgress in
                    if newProgress >= 0.70 && !hasTriggeredReachNotch {
                        hasTriggeredReachNotch = true
                        onReachNotch?()
                    }
                    if newProgress >= 0.78 && !hasTriggeredEarlyComplete {
                        hasTriggeredEarlyComplete = true
                        onEarlyComplete()
                    }
                    if newProgress >= 1.0 && !hasFinished {
                        hasFinished = true
                        onFinished()
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
    
    private static func boundingRect(of points: [CGPoint]) -> CGRect {
        guard let first = points.first else { return .null }
        var minX = first.x, maxX = first.x, minY = first.y, maxY = first.y
        for point in points.dropFirst() {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    private struct ScreenshotFlyTrajectory {
        let p0: CGPoint
        let p1: CGPoint
        let p2: CGPoint
        let p3: CGPoint
        let isLateral: Bool
        let deltaX: CGFloat
        
        init(start: CGPoint, notch: CGPoint, screenSize: CGSize) {
            let deltaX = start.x - notch.x
            let deltaY = start.y - notch.y
            let isLateral = abs(deltaX) > 40
            self.isLateral = isLateral
            self.deltaX = deltaX
            
            self.p0 = start
            self.p3 = notch
            
            if isLateral {
                let liftRatio: CGFloat = min(0.55, max(0.35, 0.45 * (abs(deltaY) / max(screenSize.height, 1))))
                let p1X = start.x - deltaX * 0.12
                let p1Y = start.y - deltaY * liftRatio
                self.p1 = CGPoint(x: p1X, y: p1Y)
                
                let p2X = notch.x + deltaX * 0.05
                let p2Y = notch.y + deltaY * 0.16
                self.p2 = CGPoint(x: p2X, y: p2Y)
            } else {
                self.p1 = CGPoint(x: notch.x, y: start.y - deltaY * 0.35)
                self.p2 = CGPoint(x: notch.x, y: start.y - deltaY * 0.70)
            }
        }
        
        func point(at t: CGFloat) -> CGPoint {
            let clampedT = max(0.0, min(1.0, t))
            let u = 1.0 - clampedT
            let tt = clampedT * clampedT
            let uu = u * u
            let uuu = uu * u
            let ttt = tt * clampedT
            
            let x = uuu * p0.x + 3 * uu * clampedT * p1.x + 3 * u * tt * p2.x + ttt * p3.x
            let y = uuu * p0.y + 3 * uu * clampedT * p1.y + 3 * u * tt * p2.y + ttt * p3.y
            return CGPoint(x: x, y: y)
        }
        
        func derivative(at t: CGFloat) -> CGPoint {
            let clampedT = max(0.0001, min(0.9999, t))
            let u = 1.0 - clampedT
            let tt = clampedT * clampedT
            let uu = u * u
            
            let dx = 3 * uu * (p1.x - p0.x) + 6 * u * clampedT * (p2.x - p1.x) + 3 * tt * (p3.x - p2.x)
            let dy = 3 * uu * (p1.y - p0.y) + 6 * u * clampedT * (p2.y - p1.y) + 3 * tt * (p3.y - p2.y)
            return CGPoint(x: dx, y: dy)
        }
        
        func tangentAngle(at t: CGFloat) -> CGFloat {
            let d = derivative(at: t)
            return atan2(d.y, d.x)
        }
    }
}

@MainActor
final class ScreenshotFlyAnimationService {
    static let shared = ScreenshotFlyAnimationService()
    
    private var activeWindow: NSPanel?
    private var completionHandler: (() -> Void)?
    private var fallbackTask: Task<Void, Never>?
    
    private init() {}
    
    func playFlyToNotchAnimation(
        image: NSImage,
        onReachNotch: (@MainActor () -> Void)? = nil,
        onComplete: @escaping () -> Void
    ) {
        guard let mainScreen = NSScreen.main else {
            onComplete()
            return
        }
        
        fallbackTask?.cancel()
        fallbackTask = nil
        activeWindow?.orderOut(nil)
        activeWindow = nil
        completionHandler = onComplete
        
        let mouseLoc = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { NSMouseInRect(mouseLoc, $0.frame, false) } ?? mainScreen
        let screenFrame = targetScreen.frame
        
        let isNotchless = targetScreen.isNotchless
        let notchY: CGFloat = isNotchless ? 4.0 : -12.0
        let notchPoint = CGPoint(x: screenFrame.width / 2.0, y: notchY)
        
        let rawStartX = mouseLoc.x - screenFrame.minX
        let rawStartY = screenFrame.maxY - mouseLoc.y
        let startX = max(70.0, min(screenFrame.width - 70.0, rawStartX))
        let startY = max(notchPoint.y + 90.0, min(screenFrame.height - 70.0, rawStartY))
        let startPoint = CGPoint(x: startX, y: startY)
        
        let imageSize = image.size
        let flightBounds = ScreenshotFlyAnimationView.flightBounds(
            start: startPoint,
            notch: notchPoint,
            screenSize: screenFrame.size,
            imageAspect: imageSize.height > 0 ? imageSize.width / imageSize.height : 1.0
        )
        let panelFrame = NSRect(
            x: screenFrame.minX + flightBounds.minX,
            y: screenFrame.maxY - flightBounds.maxY,
            width: flightBounds.width,
            height: flightBounds.height
        )
        
        let panel = OverlayPanelFactory.makePanel(
            frame: panelFrame,
            level: .floating,
            isFloatingPanel: true
        )
        panel.ignoresMouseEvents = true
        panel.alphaValue = 1.0
        
        let flyView = ScreenshotFlyAnimationView(
            image: image,
            startPoint: CGPoint(x: startPoint.x - flightBounds.minX, y: startPoint.y - flightBounds.minY),
            notchPoint: CGPoint(x: notchPoint.x - flightBounds.minX, y: notchPoint.y - flightBounds.minY),
            screenSize: screenFrame.size,
            isNotchless: isNotchless,
            onReachNotch: onReachNotch,
            onEarlyComplete: { [weak self] in
                self?.triggerEarlyCompletion()
            },
            onFinished: { [weak self, weak panel] in
                self?.cleanupPanel(panel)
            }
        )
        
        panel.contentView = NSHostingView(rootView: flyView)
        panel.orderFront(nil)
        
        self.activeWindow = panel
        self.fallbackTask = Task { @MainActor [weak self, weak panel] in
            try? await Task.sleep(for: .milliseconds(550))
            guard !Task.isCancelled else { return }
            self?.cleanupPanel(panel)
        }
    }
    
    private func triggerEarlyCompletion() {
        guard let completion = completionHandler else { return }
        completionHandler = nil
        completion()
    }
    
    private func cleanupPanel(_ panel: NSPanel?) {
        triggerEarlyCompletion()
        panel?.orderOut(nil)
        if activeWindow === panel {
            activeWindow = nil
        }
        fallbackTask?.cancel()
        fallbackTask = nil
    }
}
