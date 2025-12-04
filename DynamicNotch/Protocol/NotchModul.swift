import SwiftUI

protocol NotchModule: Identifiable, Equatable {
    var id: String { get }
    var priority: Int { get }
    var isInteractive: Bool { get }

    func compactSize() -> CGSize
    func expandedSize() -> CGSize
    func intermediateSize() -> CGSize

    func compactRadius() -> (top: CGFloat, bottom: CGFloat)
    func expandedRadius() -> (top: CGFloat, bottom: CGFloat)
    func intermediateRadius() -> (top: CGFloat, bottom: CGFloat)
    
    func compactView() -> AnyView
    func expandedView() -> AnyView
}
