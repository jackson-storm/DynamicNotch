internal import AppKit
import SwiftUI

/// Render the production pager while it is moving, rather than checking only
/// the final page. Colored substitutes identify the outgoing/incoming cards.
@main struct HomePageMotionIntegration {
 @MainActor static func main() {
  NSApplication.shared.setActivationPolicy(.prohibited)
  let suite = "com.codex.page-motion.\(UUID().uuidString)"
  let defaults = UserDefaults(suiteName:suite)!
  defer { defaults.removePersistentDomain(forName:suite) }
  defaults.set(["camera","localTimer","screenshots","calculator","sound","vpn"],forKey:"settings.homePage.order")
  defaults.set(["vpn"],forKey:"settings.homePage.disabled")
  let store=HomePageSettingsStore(defaults:defaults), vm=NotchViewModel()
  vm.settings=store; vm.select(.camera)
  let tools=HomePageTools(audioService:SystemAudioVolumeService())
  let root=PagerProbeRoot(vm:vm,store:store).environmentObject(tools).environment(\.isNotchlessScreen,true).environment(\.locale,Locale(identifier:"ru")).environment(\.colorScheme,.dark)
  let host=NSHostingView(rootView:root)
  let window=NSWindow(contentRect:CGRect(x:0,y:0,width:600,height:500),styleMask:.borderless,backing:.buffered,defer:false)
  window.contentView=host
  host.layoutSubtreeIfNeeded()
  RunLoop.main.run(until:Date().addingTimeInterval(0.5))
  var lastBitmap: NSBitmapImageRep?
  var frames: [(String, NSBitmapImageRep)] = []
  func capture() -> (red:Double?,green:Double?) {
   host.layoutSubtreeIfNeeded()
   let bitmap=host.bitmapImageRepForCachingDisplay(in:host.bounds)!
   host.cacheDisplay(in:host.bounds,to:bitmap)
   lastBitmap=bitmap
   let scale=Double(bitmap.pixelsHigh)/500
   var red=[Double](), green=[Double]()
   for y in stride(from:45,to:bitmap.pixelsHigh-30,by:2) {
    let c=bitmap.colorAt(x:bitmap.pixelsWide/2,y:y)!.usingColorSpace(.deviceRGB)!
    if c.redComponent > c.greenComponent * 1.5 && c.redComponent > c.blueComponent * 1.5 { red.append(Double(y)/scale) }
    if c.greenComponent > c.redComponent * 1.5 && c.greenComponent > c.blueComponent * 1.5 { green.append(Double(y)/scale) }
   }
   return (red.isEmpty ? nil : red.reduce(0,+)/Double(red.count),green.isEmpty ? nil : green.reduce(0,+)/Double(green.count))
  }
  var failures=[String]()
  func saveFrame(_ name: String) {
   if let lastBitmap { frames.append((name,lastBitmap)) }
  }
  let camera=capture().red!
  vm.select(.localTimer)
  var forward=[(red:Double?,green:Double?)]()
  for _ in 0..<10 { RunLoop.main.run(until:Date().addingTimeInterval(0.02)); forward.append(capture()); saveFrame("forward-"+String(forward.count)) }
  RunLoop.main.run(until:Date().addingTimeInterval(0.5))
  let timer=capture().green!
  if !forward.compactMap(\.red).contains(where:{$0 < camera-10}) { failures.append("next-page swipe must move the outgoing card UP") }
  vm.select(.camera)
  var reverse=[(red:Double?,green:Double?)]()
  for _ in 0..<10 { RunLoop.main.run(until:Date().addingTimeInterval(0.02)); reverse.append(capture()); saveFrame("reverse-"+String(reverse.count)) }
  if !reverse.compactMap(\.green).contains(where:{$0 > timer+10}) { failures.append("previous-page swipe must move the outgoing card DOWN, including a direction reversal") }
  if !reverse.contains(where:{ guard let red=$0.red,let green=$0.green else {return false};return red < green }) { failures.append("previous page must enter ABOVE the outgoing card; cards cannot cross") }
  RunLoop.main.run(until:Date().addingTimeInterval(0.5))
  vm.select(.camera, minimum:CGSize(width:0,height:304))
  RunLoop.main.run(until:Date().addingTimeInterval(0.5))
  if capture().green != nil { failures.append("retained hover height must not reveal the following page below a short card") }
  vm.isExpanded=false
  RunLoop.main.run(until:Date().addingTimeInterval(0.1))
  vm.select(.calculator); vm.isExpanded=true
  RunLoop.main.run(until:Date().addingTimeInterval(0.5))
  host.layoutSubtreeIfNeeded()
  let calculator=host.bitmapImageRepForCachingDisplay(in:host.bounds)!
  host.cacheDisplay(in:host.bounds,to:calculator)
  var orangePixels=0
  for y in stride(from:45,to:calculator.pixelsHigh-30,by:2) {
   let c=calculator.colorAt(x:calculator.pixelsWide*3/4,y:y)!.usingColorSpace(.deviceRGB)!
   if c.redComponent > 0.6 && c.redComponent > c.greenComponent * 1.2 && c.greenComponent > c.blueComponent * 1.2 { orangePixels += 1 }
  }
  if orangePixels < 20 { failures.append("reopening a later calculator page must show its actual orange controls without clipping or selecting a different row") }
  lastBitmap=calculator
  saveFrame("reopened-calculator")
  if let directory=ProcessInfo.processInfo.environment["DYNAMICNOTCH_MOTION_ARTIFACTS"] {
   for (name,bitmap) in frames {
    try! bitmap.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:directory).appendingPathComponent(name+".png"))
   }
  }
  if !failures.isEmpty { failures.forEach{print("FAIL:",$0)}; exit(1) }
  print("PASS: 5 production pager motion checks from rendered in-flight frames")
 }
}
