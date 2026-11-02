import SwiftUI
import Combine
internal import AppKit

// Isolate background services and outer gesture handling. The real window
// roots, content factory, player, view model and shared tools are compiled.
enum NotchAnimationPreset { case balanced }
enum NotchContentPriority { static let `default` = 0 }
enum NotchContentRegistry {
 enum Media { static let nowPlaying = (id:"music",priority:10) }
 enum HomePage { static let active = (id: "home", priority: 0) }
 enum LockScreen { static let activity = (id: "lock", priority: 1000) }
 enum Focus { static let active = (id: "focus.on", priority: 100); static let inactive = (id: "focus.off", priority: 100) }
}
protocol NotchSettingsProviding: AnyObject {
 var notchWidth: Int { get }; var notchHeight: Int { get }
 var isNotchTapToExpandEnabled: Bool { get }; var notchExpandInteraction: NotchExpandInteraction { get }
 var notchCollapseInteraction: NotchCollapseInteraction { get }; var notchPressHoldDuration: TimeInterval { get }
 var isNotchMouseDragGesturesEnabled: Bool { get }; var isNotchTrackpadSwipeGesturesEnabled: Bool { get }
 var isNotchSwipeDismissEnabled: Bool { get }; var isNotchSwipeRestoreEnabled: Bool { get }
 var isNotchHoverHapticEnabled: Bool { get }; var isCloseAtFocusLiveActivityEnabled: Bool { get }
}
final class TestSettings: NotchSettingsProviding {
 let notchWidth=0, notchHeight=0; let isNotchTapToExpandEnabled=true
 let notchExpandInteraction=NotchExpandInteraction.hover; let notchCollapseInteraction=NotchCollapseInteraction.hoverLeaves
 let notchPressHoldDuration=0.2; let isNotchMouseDragGesturesEnabled=true; let isNotchTrackpadSwipeGesturesEnabled=true
 let isNotchSwipeDismissEnabled=true; let isNotchSwipeRestoreEnabled=true; let isNotchHoverHapticEnabled=false
 let isCloseAtFocusLiveActivityEnabled=false
}
extension NSScreen { static func metrics(for settings: any NotchSettingsProviding) -> NotchScreenMetrics? { nil } }
extension Int { func scaled(by value: CGFloat) -> CGFloat { CGFloat(self) * value } }
extension AnyTransition {
 static func notchExpanded(notchHeight: CGFloat, baseHeight: CGFloat, isNotchlessScreen: Bool) -> AnyTransition { .identity }
 static func notchCompact(notchWidth: CGFloat, notchHeight: CGFloat, baseWidth: CGFloat, baseHeight: CGFloat, isNotchlessScreen: Bool) -> AnyTransition { .identity }
}
extension Notification.Name { static let notchContentPrioritiesDidChange = Notification.Name("priorities") }
enum HomePages { case screenshots, sound, calculator }
final class HomeSettings {
 var homePageOrder: [HomePages] = [.screenshots, .sound, .calculator]
 var homePageDisabled: [HomePages] = []
}
struct HomePageNotchContent: NotchContentProtocol {
 let id = "home"
 func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize { CGSize(width:baseWidth,height:baseHeight) }
 let notchViewModel: NotchViewModel; let settings: HomeSettings; let homePages: HomePages
 let localTimerViewModel: Int; let nowPlayingViewModel: Int; let mediaAndFilesSettings: Int; let applicationSettings: Int
 var isExpandable: Bool { true }
 func makeView() -> AnyView { AnyView(EmptyView()) }
}

enum GeneralSettingsStorage { enum Keys { static let appLanguage="language" } }
enum MediaKeyDirection { case increase, decrease }
enum MediaKeyGranularity { case standard, fine }
struct NowPlayingAppearanceOptions {
 let showsFavoriteButton: Bool = true
 let showsOutputDeviceButton: Bool = true
 let usesArtwork3DEffect: Bool = false
 let progressTintStyle: NowPlayingProgressTintStyle = .default
}
final class MediaAndFilesSettingsStore: ObservableObject { let isNowPlayingArtwork3DEffectEnabled=false; let nowPlayingAppearanceOptions = NowPlayingAppearanceOptions() }
final class ApplicationSettingsStore: ObservableObject {
 let isCloseAtFocusLiveActivityEnabled = false
 let notchWidth = 0, notchHeight = 0
 let appLanguage = DynamicNotchLanguage.russian
}
@MainActor protocol PlaybackSourceOpening: Sendable { func openPlaybackSource(_ source: NowPlayingPlaybackSource) }
@MainActor final class WorkspacePlaybackSourceOpener: PlaybackSourceOpening { func openPlaybackSource(_ source: NowPlayingPlaybackSource) {} }
final class FixtureMonitoring: NowPlayingMonitoring {
 var onSnapshotChange: ((NowPlayingSnapshot?) -> Void)?
 var commands: [NowPlayingCommand] = []
 func startMonitoring() {}
 func stopMonitoring() {}
 func send(_ command: NowPlayingCommand) { commands.append(command) }
}
typealias MediaRemoteNowPlayingService = FixtureMonitoring
final class PreviewCountdown: ObservableObject {}
enum TimerSource {
 case system(PreviewCountdown), local(PreviewCountdown)
 var isPaused: Bool { false }
 func formattedTime(at date: Date) -> String { "4:59" }
}
struct TimerNotchContent: NotchContentProtocol {
 let id="timer"; let priority=20; var supportsMinimalPresentation: Bool { true }; var isExpandable: Bool { true }
 func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize { CGSize(width:baseWidth+110,height:baseHeight) }
 func makeView() -> AnyView { AnyView(Text("4:59")) }
 func makeMinimalView() -> AnyView { AnyView(TimerDetachedActivityView(source:.local(PreviewCountdown()))) }
}

final class NotchEventCoordinator {}
final class AirDropNotchViewModel: ObservableObject {}
final class NotchAirDropController: ObservableObject {}
final class SettingsViewModel: ObservableObject { let application = ApplicationSettingsStore() }
final class LockScreenLiveActivityAnimator: ObservableObject {}
struct HomePagePageIndicatorView: View {
 let notchViewModel: NotchViewModel; let settingsViewModel: SettingsViewModel
 var body: some View { EmptyView() }
}
struct NotchDragAndDropDestinationOverlay: View {
 let airDropViewModel: AirDropNotchViewModel; let airDropController: NotchAirDropController; let settingsViewModel: SettingsViewModel
 var body: some View { EmptyView() }
}
struct NotchInteractiveBodyView: View {
 @ObservedObject var notchViewModel: NotchViewModel
 let settingsViewModel: SettingsViewModel
 var body: some View {
  if let content = notchViewModel.displayedContent {
   if notchViewModel.isDisplayingExpandedLiveActivity { content.makeExpandedView() }
   else { content.makeView() }
  }
 }
}
extension NSScreen { static func preferredNotchScreen(for settings: ApplicationSettingsStore) -> NSScreen? { .main } }
