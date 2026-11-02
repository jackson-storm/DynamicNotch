internal import AppKit
// The production page view, native input, sizing content and controls are used.
// Unrelated background services and the outer presentation host are replaced so
// tests never launch app copies, request permissions, or change user settings.
import SwiftUI
import Combine

enum MediaKeyDirection { case increase, decrease }
enum MediaKeyGranularity { case standard, fine }
enum GeneralSettingsStorage {
 enum Keys {
  static let appLanguage = "settings.general.language.app"
  static let homePageLiveActivity = "settings.homePage.liveActivity"
  static let homePagePageIndicator = "settings.homePage.pageIndicator"
  static let homePageIndicatorSize = "settings.homePage.indicatorSize"
  static let homePageOrder = "settings.homePage.order"
  static let homePageDisabled = "settings.homePage.disabled"
 }
 static let defaultValues: [String: Any] = [:]
}
class LocalTimerViewModel {}
class NowPlayingViewModel {}
class MediaAndFilesSettingsStore {}
class ApplicationSettingsStore {}
extension NSScreen { static func preferredNotchScreen(for settings: ApplicationSettingsStore) -> NSScreen? { .main } }
enum NotchContentPriority { static let `default` = 0 }
enum NotchContentRegistry { enum HomePage { static let active = (id:"home",priority:0) } }
enum TestEvent { case showLiveActivity(HomePageNotchContent) }
@MainActor final class NotchViewModel: ObservableObject {
 struct Model { var baseWidth: CGFloat = 120; var baseHeight: CGFloat = 35 }
 let notchModel = Model()
 var isDynamicIsland = true
 var isHoveringScrollableContent = false
 var isHomePageOnLastPage = false
 @Published var isExpanded = true
 var settings: HomePageSettingsStore!
 var minimumExpandedSize = CGSize.zero
 var isDisplayingExpandedLiveActivity: Bool { isExpanded }
 var displayedContent: (any NotchContentProtocol)? { isExpanded ? makeContent(page) : nil }
 func makeContent(_ target: HomePages, minimum: CGSize = .zero) -> HomePageNotchContent {
  HomePageNotchContent(notchViewModel:self,settings:settings,homePages:target,localTimerViewModel:LocalTimerViewModel(),nowPlayingViewModel:NowPlayingViewModel(),mediaAndFilesSettings:MediaAndFilesSettingsStore(),applicationSettings:ApplicationSettingsStore(),minimumExpandedSize:minimum)
 }
 var dismissCount = 0
 @Published var page: HomePages = .calculator
 @Published var presentedNotchSize = CGSize(width: 380, height: 180)
 func send(_ event: TestEvent) {
  if case .showLiveActivity(let content) = event { select(content.homePages, minimum: content.minimumExpandedSize) }
 }
 func select(_ target: HomePages, minimum: CGSize = .zero) {
  withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
   page=target
   minimumExpandedSize=minimum
   presentedNotchSize=makeContent(target,minimum:minimum).expandedDynamicIslandSize(baseWidth:120,baseHeight:35)
  }
 }
 func dismissActiveContent() { dismissCount += 1; isExpanded = false }
}
struct CameraNotchView: View {
 let notchViewModel: NotchViewModel; let settings: HomePageSettingsStore
 let localTimerViewModel: LocalTimerViewModel; let nowPlayingViewModel: NowPlayingViewModel
 let mediaAndFilesSettings: MediaAndFilesSettingsStore; let applicationSettings: ApplicationSettingsStore
 var isActive = true
 var body: some View { Color.red.frame(maxWidth:.infinity,maxHeight:.infinity) }
}
struct LocalTimerSetupNotchView: View {
 let localTimerViewModel: LocalTimerViewModel
 var body: some View { Color.green.frame(maxWidth:.infinity,maxHeight:.infinity) }
}
struct VpnPageNotchView: View {
 let notchViewModel: NotchViewModel
 var body: some View { Text("VPN").frame(maxWidth:.infinity,maxHeight:.infinity) }
}
struct PagerProbeRoot: View {
 @ObservedObject var vm: NotchViewModel
 @ObservedObject var store: HomePageSettingsStore
 var body: some View {
  VStack {
   Text(verbatim:"Selected: \(vm.page.rawValue) / height: \(Int(vm.presentedNotchSize.height))")
   if vm.isExpanded { HomePageNotchView(notchViewModel:vm,settings:store,localTimerViewModel:LocalTimerViewModel(),nowPlayingViewModel:NowPlayingViewModel(),mediaAndFilesSettings:MediaAndFilesSettingsStore(),applicationSettings:ApplicationSettingsStore(),initialPage:vm.page,minimumExpandedSize:vm.minimumExpandedSize)
    .frame(width:vm.presentedNotchSize.width,height:vm.presentedNotchSize.height)
    .background(.black)
    .clipShape(RoundedRectangle(cornerRadius:24))
   }
   Spacer(minLength:0)
  }.padding(20).frame(width:600,height:500).background(Color.gray.opacity(0.3))
 }
}
