import SwiftUI
internal import AppKit

private struct DependencyContent: NotchContentProtocol {
 let id = "environment.probe"
 let expectedTools: HomePageTools
 let didResolve: () -> Void
 var isExpandable: Bool { true }
 var priority: Int { 1000 }
 func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize { CGSize(width:380,height:270) }
 func makeView() -> AnyView { AnyView(DependencyProbe(expectedTools:expectedTools,didResolve:didResolve)) }
}

/// Verify the scene boundary supplies both objects, including exact shared
/// identity. The missing sound object in the lock-overlay scene caused SIGTRAP.
private struct DependencyProbe: View {
 @EnvironmentObject private var tools: HomePageTools
 @EnvironmentObject private var sound: SoundControlModel
 let expectedTools: HomePageTools
 let didResolve: () -> Void
 var body: some View {
  let matches = tools === expectedTools && sound === expectedTools.sound
  Text("Presentation dependencies")
   .onAppear { precondition(matches, "Window must share the application's tools and sound model"); didResolve() }
 }
}

@main struct PresentationDependencyTests {
 @MainActor static func main() {
  NSApplication.shared.setActivationPolicy(.prohibited)
  let scene = CommandLine.arguments.last!
  let service = FixtureMonitoring()
  let suite = "com.codex.presentation-check.\(UUID().uuidString)"
  let defaults=UserDefaults(suiteName:suite)!
  defer { defaults.removePersistentDomain(forName:suite) }
  let player=NowPlayingViewModel(service:service,lyricsProvider:InactiveLyricsProvider(),favoritesStore:defaults)
  player.startMonitoring()
  service.onSnapshotChange?(NowPlayingSnapshot(title:"Проверка плеера",artist:"",album:"",duration:240,elapsedTime:30,playbackRate:1,artworkData:nil,refreshedAt:.now))
  let tools=HomePageTools(audioService:SystemAudioVolumeService())
  let settings=SettingsViewModel()
  let vm=NotchViewModel(settings:TestSettings(),hideDelay:0,queueDelay:0,screenMetricsProvider:{ _ in (width:1440,topInset:0,notchSize:nil) })
  vm.send(.showLiveActivity(NowPlayingNotchContent(nowPlayingViewModel:player,settings:MediaAndFilesSettingsStore(),applicationSettings:settings.application)))
  RunLoop.main.run(until:Date().addingTimeInterval(0.1))
  let primary=AnyView(NotchView(notchEventCoordinator:NotchEventCoordinator(),homePageTools:tools,notchViewModel:vm,airDropViewModel:AirDropNotchViewModel(),airDropController:NotchAirDropController(),settingsViewModel:settings))
  let overlay=AnyView(LockScreenNotchOverlayView(homePageTools:tools,notchViewModel:vm,settingsViewModel:settings,animator:LockScreenLiveActivityAnimator()))
  let roots = scene == "both" ? [primary,overlay] : [scene == "primary" ? primary : overlay]
  let hosts=roots.map { NSHostingView(rootView:$0) }
  let windows=hosts.map { host in
   let window=NSWindow(contentRect:CGRect(x:0,y:0,width:500,height:360),styleMask:.borderless,backing:.buffered,defer:false)
   window.contentView=host
   return window
  }
  defer { withExtendedLifetime(windows) {} }
  // Keep the overlay retained and hidden, just as it is after an unlock.
  // Changes from the shared engine still cause SwiftUI to render its player.
  for _ in 0..<5 {
   vm.handleActiveContentTap()
   RunLoop.main.run(until:Date().addingTimeInterval(0.2))
   precondition(vm.isDisplayingExpandedLiveActivity)
   for host in hosts {
    host.layoutSubtreeIfNeeded()
    let bitmap=host.bitmapImageRepForCachingDisplay(in:host.bounds)!
    host.cacheDisplay(in:host.bounds,to:bitmap)
    precondition(bitmap.pixelsWide > 0 && bitmap.pixelsHigh > 0)
   }
   vm.handleOutsideClick()
   RunLoop.main.run(until:Date().addingTimeInterval(0.2))
   precondition(!vm.isDisplayingExpandedLiveActivity)
  }
  var resolved=0
  vm.send(.showLiveActivity(DependencyContent(expectedTools:tools,didResolve:{resolved += 1})))
  RunLoop.main.run(until:Date().addingTimeInterval(0.2))
  hosts.forEach { $0.layoutSubtreeIfNeeded() }
  precondition(resolved == hosts.count,"Both shared dependencies must resolve in every retained window root")
  print("PASS: \(scene) scene renders five real player expansions per window and shares both presentation dependencies")
 }
}
