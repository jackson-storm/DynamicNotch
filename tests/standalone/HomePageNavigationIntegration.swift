internal import AppKit
import SwiftUI

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
