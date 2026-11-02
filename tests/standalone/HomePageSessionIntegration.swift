import SwiftUI
import Combine
internal import AppKit

// Exercise the production engine, view model and memory together. Only UI,
// background services and persisted settings are replaced; no app is launched.
enum NotchAnimationPreset { case balanced }
enum NotchContentPriority { static let `default` = 0 }
enum NotchContentRegistry {
 enum Media { static let nowPlaying = (id: "music", priority: 10) }
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
struct PlaybackActivity: NotchContentProtocol {
 let id = NotchContentRegistry.Media.nowPlaying.id
 let priority = 10
 var isExpandable: Bool { true }
 var supportsMinimalPresentation: Bool { true }
 var prefersCompactPresentation: Bool { true }
 func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize { CGSize(width:baseWidth+70,height:baseHeight) }
 func makeView() -> AnyView { AnyView(EmptyView()) }
}
@main struct HomePageSessionIntegration {
 @MainActor static func main() async {
  let vm = NotchViewModel(settings:TestSettings(),hideDelay:0,queueDelay:0,screenMetricsProvider:{ _ in (width:1440,topInset:0,notchSize:nil) })
  let settings = HomeSettings()
  func show(_ page: HomePages) {
   vm.send(.showLiveActivity(HomePageNotchContent(notchViewModel:vm,settings:settings,homePages:page,localTimerViewModel:0,nowPlayingViewModel:0,mediaAndFilesSettings:0,applicationSettings:0)))
  }
  func settle() async { try? await Task.sleep(for:.milliseconds(180)) }
  var count=0
  func check(_ ok: Bool, _ label: String) { guard ok else { print("FAIL:",label); exit(1) }; count += 1 }
  func page() -> HomePages? { (vm.notchModel.liveActivityContent as? HomePageNotchContent)?.homePages }
  show(.sound); await settle(); vm.expandActiveLiveActivity(); await settle()
  try? await Task.sleep(for:.seconds(5.1))
  check(vm.notchModel.isExpanded && page() == .sound,"an open page does not reset after five seconds")
  vm.handleOutsideClick(); await settle(); vm.expandActiveLiveActivity(); await settle()
  check(vm.notchModel.isExpanded && page() == .sound,"brief close retains selected sound page")
  show(.calculator); vm.handleOutsideClick(); await settle()
  try? await Task.sleep(for:.seconds(5.1))
  vm.expandActiveLiveActivity(); await settle()
  check(vm.notchModel.isExpanded && page() == .screenshots,"expired close opens first page through real hover expansion gateway")
  show(.calculator); settings.homePageOrder = [.sound,.screenshots,.calculator]
  vm.handleOutsideClick(); await settle(); try? await Task.sleep(for:.seconds(5.1))
  vm.handleActiveContentTap(); await settle()
  check(page() == .sound,"click expansion honors reordered first page")
  vm.interactionRegionProvider = { CGRect(x:100,y:200,width:300,height:100) }
  check(vm.isPointerInsideInteractionRegion(CGPoint(x:150,y:250)),"hover containment uses actual window owner")
  check(!vm.isPointerInsideInteractionRegion(CGPoint(x:50,y:250)),"a genuine pointer exit remains outside")
  vm.handleOutsideClick(); await settle()
  vm.send(.showLiveActivity(PlaybackActivity())); await settle()
  vm.expandActiveLiveActivity(); await settle()
  check(vm.notchModel.content?.id == "music" && vm.notchModel.isExpanded,"playback opens the player by default")
  vm.dismissActiveContent(); await settle()
  check(vm.notchModel.content?.id == "home" && vm.notchModel.isExpanded,"one swipe on the player opens tools directly")
  check(!vm.canDismissWithTrackpadSwipe,"tool page gestures stay with the home pager after leaving the player")
  for _ in 0..<5 { vm.send(.showLiveActivity(PlaybackActivity())) }
  await settle()
  check(vm.notchModel.content?.id == "home" && vm.notchModel.isExpanded,"playback updates cannot steal the tools session")
  show(.calculator); await settle()
  check(page() == .calculator && vm.notchModel.isExpanded,"tools remain navigable during ongoing playback")
  vm.handleOutsideClick(); await settle()
  check(vm.notchModel.content?.id == "music" && !vm.notchModel.isExpanded,"closing tools restores the default player")
  vm.expandActiveLiveActivity(); await settle()
  check(vm.notchModel.content?.id == "music" && vm.notchModel.isExpanded,"next hover opens the default player again")
  vm.handleOutsideClick(); await settle()
  vm.dismissActiveContent(); await settle()
  check(vm.notchModel.content?.id == "home" && vm.notchModel.isExpanded,"a swipe on compact playback can also open tools")
  print("PASS: \(count) production view-model checks including real five-second waits and player-to-tools swipes")
 }
}
