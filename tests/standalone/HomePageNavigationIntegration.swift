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
 struct Model { var baseHeight: CGFloat = 35 }
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
 var body: some View { Text("CAMERA").frame(maxWidth:.infinity,maxHeight:.infinity) }
}
struct LocalTimerSetupNotchView: View {
 let localTimerViewModel: LocalTimerViewModel
 var body: some View { Text("TIMER").frame(maxWidth:.infinity,maxHeight:.infinity) }
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
@main struct PagerRepro {
 @MainActor static func main() throws {
  NSApplication.shared.setActivationPolicy(.prohibited)
  let suite="com.codex.pager-repro.\(UUID().uuidString)"
  let defaults=UserDefaults(suiteName:suite)!
  defer { defaults.removePersistentDomain(forName:suite) }
  defaults.set(["screenshots","sound","calculator","localTimer","camera","vpn"],forKey:"settings.homePage.order")
  defaults.set(["vpn"],forKey:"settings.homePage.disabled")
  let store=HomePageSettingsStore(defaults:defaults)
  let vm=NotchViewModel()
  vm.settings=store
  vm.select(.calculator)
  let tools=HomePageTools(audioService:SystemAudioVolumeService())
  let root=PagerProbeRoot(vm:vm,store:store).environmentObject(tools).environment(\.isNotchlessScreen,true).environment(\.locale,Locale(identifier:"ru")).environment(\.colorScheme,.dark)
  let host=NSHostingView(rootView:root)
  let window=NSWindow(contentRect:CGRect(x:0,y:0,width:600,height:500),styleMask:.borderless,backing:.buffered,defer:false)
  window.contentView=host
  host.layoutSubtreeIfNeeded()
  RunLoop.main.run(until:Date().addingTimeInterval(0.5))
  var failures: [String] = []
  vm.isExpanded = false
  RunLoop.main.run(until:Date().addingTimeInterval(0.1))
  if vm.page != .calculator { failures.append("collapse resets the selected calculator page to \(vm.page.rawValue)") }
  vm.isExpanded = true
  RunLoop.main.run(until:Date().addingTimeInterval(0.1))
  if vm.page != .calculator { failures.append("reopening changed the selected page") }
  func findInput(_ view: NSView) -> HomePageScrollMonitorView? {
   if let input=view as? HomePageScrollMonitorView { return input }
   for child in view.subviews { if let input=findInput(child) { return input } }
   return nil
  }
  guard let input = findInput(host) else { fatalError("No production page input attached") }
  input.onStep?(1, CGSize(width:48,height:304))
  RunLoop.main.run(until:Date().addingTimeInterval(0.05))
  if vm.page != .localTimer || vm.presentedNotchSize.height < 304 { failures.append("switching to a shorter page ejects the stationary pointer") }
  vm.isExpanded = false
  RunLoop.main.run(until:Date().addingTimeInterval(0.05))
  vm.isExpanded = true
  RunLoop.main.run(until:Date().addingTimeInterval(0.05))
  if vm.page != .localTimer || vm.presentedNotchSize.height != 165 { failures.append("reopening must retain the timer and restore its natural size") }
  guard let secondInput = findInput(host) else { fatalError("Input detached after selection") }
  secondInput.onStep?(1, CGSize(width:48,height:304))
  RunLoop.main.run(until:Date().addingTimeInterval(0.05))
  guard let lastInput = findInput(host) else { fatalError("Input detached on last page") }
  lastInput.onStep?(1, CGSize(width:48,height:304))
  RunLoop.main.run(until:Date().addingTimeInterval(0.05))
  if vm.dismissCount != 0 || !vm.isExpanded || vm.page != .camera { failures.append("scrolling past the last page closes the island") }
  vm.select(.screenshots)
  RunLoop.main.run(until:Date().addingTimeInterval(0.05))
  guard let rapidInput = findInput(host) else { fatalError("Missing rapid navigation input") }
  for _ in 0..<10 {
   for direction in [1,1,1,1,1,-1,-1,-1,-1,-1] { rapidInput.onStep?(direction, .zero) }
  }
  RunLoop.main.run(until:Date().addingTimeInterval(0.05))
  if vm.page != .screenshots || !vm.isExpanded || vm.dismissCount != 0 { failures.append("rapid navigation diverged from the active page") }
  vm.select(.calculator)
  RunLoop.main.run(until:Date().addingTimeInterval(0.05))
  store.homePageDisabled.insert(.calculator)
  RunLoop.main.run(until:Date().addingTimeInterval(0.05))
  if vm.page != .screenshots { failures.append("disabled current page remains selected") }
  store.homePageDisabled.remove(.calculator)
  vm.select(.calculator)
  RunLoop.main.run(until:Date().addingTimeInterval(0.05))
  guard let outgoingInput = findInput(host) else { fatalError("Missing outgoing input") }
  vm.isExpanded = false
  outgoingInput.onStep?(1, .zero)
  RunLoop.main.run(until:Date().addingTimeInterval(0.05))
  if vm.page != .calculator { failures.append("outgoing view handled a late gesture after collapse") }
  if !failures.isEmpty {
   failures.forEach { print("FAIL:",$0) }
   exit(1)
  }
  print("PASS: 8 production home-page navigation regressions, including 100 rapid transitions")
 }
}
