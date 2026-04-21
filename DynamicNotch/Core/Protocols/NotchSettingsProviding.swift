import Foundation

protocol NotchSettingsProviding: AnyObject {
    var notchWidth: Int { get }
    var notchHeight: Int { get }
    var displayLocation: NotchDisplayLocation { get }
    var screenSelectionPreferences: NotchScreenSelectionPreferences { get }
    var notchAnimationPreset: NotchAnimationPreset { get }
    var isNotchTapToExpandEnabled: Bool { get }
    var isNotchMouseDragGesturesEnabled: Bool { get }
    var isNotchTrackpadSwipeGesturesEnabled: Bool { get }
    var isNotchSwipeDismissEnabled: Bool { get }
    var isNotchSwipeRestoreEnabled: Bool { get }
}
