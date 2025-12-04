import SwiftUI
import Combine

struct AnyNotchModule: NotchModule {
    let id: String
    let priority: Int
    var isInteractive: Bool

    private let _compactSize: () -> CGSize
    private let _expandedSize: () -> CGSize
    private let _intermediateSize: () -> CGSize

    private let _compactRadius: () -> (top: CGFloat, bottom: CGFloat)
    private let _expandedRadius: () -> (top: CGFloat, bottom: CGFloat)
    private let _intermediateRadius: () -> (top: CGFloat, bottom: CGFloat)

    private let _compactView: () -> AnyView
    private let _expandedView: () -> AnyView

    init<M: NotchModule>(_ m: M) {
        id = m.id
        priority = m.priority
        isInteractive = m.isInteractive

        _compactSize = m.compactSize
        _expandedSize = m.expandedSize
        _intermediateSize = m.intermediateSize

        _compactRadius = m.compactRadius
        _expandedRadius = m.expandedRadius
        _intermediateRadius = m.intermediateRadius

        _compactView = { m.compactView() }
        _expandedView = { m.expandedView() }
    }

    func compactSize() -> CGSize { _compactSize() }
    func expandedSize() -> CGSize { _expandedSize() }
    func intermediateSize() -> CGSize { _intermediateSize() }

    func compactRadius() -> (top: CGFloat, bottom: CGFloat) { _compactRadius() }
    func expandedRadius() -> (top: CGFloat, bottom: CGFloat) { _expandedRadius() }
    func intermediateRadius() -> (top: CGFloat, bottom: CGFloat) { _intermediateRadius() }

    func compactView() -> AnyView { _compactView() }
    func expandedView() -> AnyView { _expandedView() }
}

extension NotchModule {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
