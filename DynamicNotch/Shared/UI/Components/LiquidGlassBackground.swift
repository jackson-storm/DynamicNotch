import SwiftUI
internal import AppKit
import ObjectiveC

private final class LiquidGlassHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}

private final class LiquidGlassContainerView<Content: View>: NSView {
    weak var glassView: NSView?
    var hostingView: LiquidGlassHostingView<Content>?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if let hitView = super.hitTest(point) {
            return hostingView ?? hitView
        }
        return nil
    }

    private var observedBackdropLayers: [CALayer] = []
    private var hasScheduledBackdropSetup = false
    private var retryCount = 0
    private let windowServerAwareKeyPath = "windowServerAware"
    private let scaleKeyPath = "scale"

    deinit {
        removeObservers()
    }

    override func removeFromSuperview() {
        removeObservers()
        super.removeFromSuperview()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        glassView?.perform(NSSelectorFromString("_windowChangedKeyState"))
        glassView?.setValue(0, forKey: "_subduedState")
        glassView?.setValue(0, forKey: "_interactionState")
        configureBackdropLayers()
        scheduleBackdropSetup()
    }

    override func layout() {
        super.layout()
        configureBackdropLayers()
    }

    func scheduleBackdropSetup() {
        guard !hasScheduledBackdropSetup else { return }
        hasScheduledBackdropSetup = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            self.hasScheduledBackdropSetup = false
            self.configureBackdropLayers()
        }
    }

    func configureBackdropLayers() {
        guard let glassView else { return }
        glassView.layoutSubtreeIfNeeded()

        setBackdropPropertiesInViewHierarchy(glassView)
        let newBackdropLayers = collectBackdropLayersFromViewHierarchy(glassView)

        if newBackdropLayers.isEmpty && retryCount < 10 {
            retryCount += 1
            scheduleBackdropSetup()
            return
        }

        guard newBackdropLayers != observedBackdropLayers else { return }

        removeObservers()
        observedBackdropLayers = newBackdropLayers
        for backdrop in observedBackdropLayers {
            backdrop.addObserver(self, forKeyPath: windowServerAwareKeyPath, options: [.old, .new], context: nil)
            backdrop.addObserver(self, forKeyPath: scaleKeyPath, options: [.old, .new], context: nil)
        }
    }

    private func setBackdropProperties(in layer: CALayer) {
        let className = NSStringFromClass(type(of: layer))
        if className.contains("CABackdropLayer") {
            layer.setValue(true, forKey: windowServerAwareKeyPath)
            layer.setValue(1.0, forKey: scaleKeyPath)
            layer.setValue(true, forKey: "ignoresScreenClip")
            layer.setValue(false, forKey: "disablesOccludedBackdropBlurs")
            layer.setValue(true, forKey: "enabled")

            if let filters = layer.filters {
                for filter in filters {
                    if let nsFilter = filter as? NSObject {
                        let filterType = (nsFilter.value(forKey: "type") as? String) ?? ""
                        let filterName = (nsFilter.value(forKey: "name") as? String) ?? ""
                        if filterType == "gaussianBlur" || filterName == "gaussianBlur" {
                            nsFilter.setValue(35.0, forKey: "inputRadius")
                        } else if filterType == "colorSaturate" || filterName == "colorSaturate" {
                            nsFilter.setValue(1.8, forKey: "inputAmount")
                        }
                    }
                }
            }
        }

        layer.sublayers?.forEach { setBackdropProperties(in: $0) }
    }

    private func setBackdropPropertiesInViewHierarchy(_ view: NSView) {
        if let layer = view.layer {
            setBackdropProperties(in: layer)
        }
        for subview in view.subviews {
            setBackdropPropertiesInViewHierarchy(subview)
        }
    }

    private func collectBackdropLayers(in layer: CALayer) -> [CALayer] {
        var results: [CALayer] = []
        if NSStringFromClass(type(of: layer)).contains("CABackdropLayer") {
            results.append(layer)
        }
        layer.sublayers?.forEach { results.append(contentsOf: collectBackdropLayers(in: $0)) }
        return results
    }

    private func collectBackdropLayersFromViewHierarchy(_ view: NSView) -> [CALayer] {
        var results: [CALayer] = []
        if let layer = view.layer {
            results.append(contentsOf: collectBackdropLayers(in: layer))
        }
        for subview in view.subviews {
            results.append(contentsOf: collectBackdropLayersFromViewHierarchy(subview))
        }
        return results
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == windowServerAwareKeyPath {
            guard let layer = object as? CALayer else { return }
            let isAware = (change?[.newKey] as? NSNumber)?.boolValue ?? (change?[.newKey] as? Bool) ?? false
            if !isAware {
                layer.setValue(true, forKey: windowServerAwareKeyPath)
                layer.setValue(true, forKey: "ignoresScreenClip")
                layer.setValue(false, forKey: "disablesOccludedBackdropBlurs")
            }
        } else if keyPath == scaleKeyPath {
            guard let layer = object as? CALayer else { return }
            if let newScale = (change?[.newKey] as? NSNumber)?.doubleValue, newScale != 1.0 {
                layer.setValue(1.0, forKey: scaleKeyPath)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    private func removeObservers() {
        for layer in observedBackdropLayers {
            layer.removeObserver(self, forKeyPath: windowServerAwareKeyPath)
            layer.removeObserver(self, forKeyPath: scaleKeyPath)
        }
        observedBackdropLayers.removeAll()
    }
}

public enum LiquidGlassVariant: Int, CaseIterable, Identifiable, Sendable {
    case v0  = 0,  v1  = 1,  v2  = 2,  v3  = 3,  v4  = 4
    case v5  = 5,  v6  = 6,  v7  = 7,  v8  = 8,  v9  = 9
    case v10 = 10, v11 = 11, v12 = 12, v13 = 13, v14 = 14
    case v15 = 15, v16 = 16, v17 = 17, v18 = 18, v19 = 19

    public var id: Int { rawValue }
    public static let supportedRange = 0...19
    public static var defaultVariant: LiquidGlassVariant { .v8 }
    
    public static func clamped(_ rawValue: Int) -> LiquidGlassVariant {
        let clamped = min(max(rawValue, supportedRange.lowerBound), supportedRange.upperBound)
        return LiquidGlassVariant(rawValue: clamped) ?? .defaultVariant
    }
}

public struct LiquidGlassBackground<Content: View>: NSViewRepresentable {
    private let content: Content
    private let cornerRadius: CGFloat
    private let variant: LiquidGlassVariant
    private let hideTopBorder: Bool

    public init(
        variant: LiquidGlassVariant = .defaultVariant,
        cornerRadius: CGFloat = 10,
        hideTopBorder: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.variant = variant
        self.hideTopBorder = hideTopBorder
    }

    @inline(__always)
    private func setterSelector(for key: String, privateVariant: Bool = true) -> Selector? {
        guard !key.isEmpty else { return nil }
        let name: String
        if privateVariant {
            let cleaned = key.hasPrefix("_") ? key : "_" + key
            name = "set" + cleaned
        } else {
            let first = String(key.prefix(1)).uppercased()
            let rest  = String(key.dropFirst())
            name = "set" + first + rest
        }
        return NSSelectorFromString(name + ":")
    }

    private typealias VariantSetterIMP = @convention(c) (AnyObject, Selector, Int) -> Void

    private func callPrivateVariantSetter(on object: AnyObject, value: Int) {
        guard
            let sel   = setterSelector(for: "variant", privateVariant: true),
            let m     = class_getInstanceMethod(object_getClass(object), sel)
        else {
            #if DEBUG
            print("✗ LiquidGlassBackground: selector set_variant: not found. falling back to default")
            #endif
            return
        }
        let imp = method_getImplementation(m)
        let f   = unsafeBitCast(imp, to: VariantSetterIMP.self)
        f(object, sel, value)
    }

    public func makeNSView(context: Context) -> NSView {
        if let glassType = NSClassFromString("NSGlassEffectView") as? NSView.Type {
            let container = LiquidGlassContainerView<Content>(frame: .zero)
            container.translatesAutoresizingMaskIntoConstraints = false
            container.wantsLayer = true

            let glass = glassType.init(frame: .zero)
            glass.translatesAutoresizingMaskIntoConstraints = false
            glass.wantsLayer = true
            glass.setValue(cornerRadius, forKey: "cornerRadius")
            callPrivateVariantSetter(on: glass, value: variant.rawValue)
            glass.perform(NSSelectorFromString("_windowChangedKeyState"))
            glass.setValue(0, forKey: "_subduedState")
            glass.setValue(0, forKey: "_interactionState")

            if let visualEffect = glass as? NSVisualEffectView {
                visualEffect.state = .active
            }

            let hosting = LiquidGlassHostingView(rootView: content)
            hosting.translatesAutoresizingMaskIntoConstraints = false
            glass.setValue(hosting, forKey: "contentView")

            let topConstant: CGFloat = hideTopBorder ? -10 : 0
            let bottomConstant: CGFloat = hideTopBorder ? 10 : 0
            
            container.addSubview(glass)
            NSLayoutConstraint.activate([
                glass.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                glass.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                glass.topAnchor.constraint(equalTo: container.topAnchor, constant: topConstant),
                glass.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: bottomConstant)
            ])

            container.glassView = glass
            container.hostingView = hosting
            container.configureBackdropLayers()
            container.scheduleBackdropSetup()
            return container
        }

        let fallback = NSVisualEffectView()
        fallback.material = .underWindowBackground
        fallback.state = .active

        let hosting = LiquidGlassHostingView(rootView: content)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        fallback.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: fallback.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: fallback.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: fallback.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: fallback.bottomAnchor)
        ])
        return fallback
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        if let container = nsView as? LiquidGlassContainerView<Content>,
           let glass = container.glassView {
            container.hostingView?.rootView = content
            glass.setValue(cornerRadius, forKey: "cornerRadius")
            callPrivateVariantSetter(on: glass, value: variant.rawValue)
            container.configureBackdropLayers()
            container.scheduleBackdropSetup()
            return
        }

        if let hosting = nsView.subviews.first as? LiquidGlassHostingView<Content> {
            hosting.rootView = content
        }
    }
}
