import Foundation

protocol NotchSettingsProviding: AnyObject {
    var notchWidth: Int { get }
    var notchHeight: Int { get }
    
    var displayLocation: NotchDisplayLocation { get }
    var screenSelectionPreferences: NotchScreenSelectionPreferences { get }
    
    var notchExpandInteraction: NotchExpandInteraction { get }
    var notchCollapseInteraction: NotchCollapseInteraction { get }
    var isNotchHoverHapticEnabled: Bool { get }
    var isCloseAtFocusLiveActivityEnabled: Bool { get }
}
