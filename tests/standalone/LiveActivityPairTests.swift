import Foundation
import SwiftUI

enum NotchContentPriority { static let `default` = 0 }
enum NotchAnimationPreset { case balanced }

private struct FixtureActivity: NotchContentProtocol {
    let id: String
    let priority: Int
    var supportsMinimalPresentation = true
    var prefersCompactPresentation = false
    var isExpandable: Bool { true }
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize { CGSize(width: baseWidth + 60, height: baseHeight) }
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize { CGSize(width: baseWidth + 180, height: baseHeight + 180) }
    func makeView() -> AnyView { AnyView(EmptyView()) }
}

@main
struct LiveActivityPairTests {
    @MainActor
    static func main() async {
        let engine = NotchEngine(animations: { .balanced }, hideDelay: 0, queueDelay: 0)
        engine.send(.showLiveActivity(FixtureActivity(id: "music", priority: 10, prefersCompactPresentation: true)))
        engine.send(.showLiveActivity(FixtureActivity(id: "timer", priority: 20)))
        try? await Task.sleep(for: .milliseconds(150))
        guard engine.notchModel.liveActivityContent?.id == "music" else {
            print("FAIL: music and timer must share the island with music as the main presentation; actual:",engine.notchModel.liveActivityContent?.id ?? "nil")
            exit(1)
        }
        var passed = 1
        func expect(_ condition: Bool, _ message: String) {
            guard condition else { print("FAIL:",message); exit(1) }
            passed += 1
        }
        func settle() async { try? await Task.sleep(for: .milliseconds(80)) }
        expect(engine.visibleLiveActivities.count == 2, "both ongoing activities remain available")
        engine.send(.selectLiveActivity(id:"timer"))
        await settle()
        expect(engine.notchModel.liveActivityContent?.id == "timer" && engine.notchModel.isExpanded, "selecting timer opens its own controls")
        engine.send(.showLiveActivity(FixtureActivity(id:"music",priority:10,prefersCompactPresentation:true)))
        await settle()
        expect(engine.notchModel.liveActivityContent?.id == "timer", "music update cannot steal an expanded timer")
        engine.collapse()
        await settle()
        expect(engine.notchModel.liveActivityContent?.id == "music" && !engine.notchModel.isExpanded, "collapse restores the main music presentation")
        engine.send(.hideLiveActivity(id:"timer"))
        expect(engine.visibleLiveActivities.count == 1 && engine.visibleLiveActivities[0].id == "music", "ending secondary timer removes its bubble immediately")
        engine.send(.showLiveActivity(FixtureActivity(id:"timer",priority:20)))
        await settle()
        engine.handleActiveContentTap()
        engine.send(.showLiveActivity(FixtureActivity(id:"music",priority:10,prefersCompactPresentation:false)))
        await settle()
        expect(engine.notchModel.liveActivityContent?.id == "music" && engine.notchModel.isExpanded, "pause retains the expanded player so play can resume")
        engine.collapse()
        await settle()
        expect(engine.notchModel.liveActivityContent?.id == "timer", "paused music can yield the compact primary presentation to timer")
        engine.send(.selectLiveActivity(id:"music"))
        await settle()
        expect(engine.notchModel.liveActivityContent?.id == "music" && engine.notchModel.isExpanded, "secondary music remains independently selectable")
        engine.send(.hideLiveActivity(id:"music"))
        await settle()
        expect(engine.notchModel.liveActivityContent?.id == "timer" && engine.visibleLiveActivities.count == 1, "ending selected media restores remaining timer")
        engine.send(.showLiveActivity(FixtureActivity(id:"music",priority:10,prefersCompactPresentation:true)))
        await settle()
        engine.send(.selectLiveActivity(id:"music"))
        await settle()
        engine.send(.showLiveActivity(FixtureActivity(id:"urgent",priority:1000,supportsMinimalPresentation:false)))
        await settle()
        expect(engine.notchModel.liveActivityContent?.id == "urgent", "urgent activity can interrupt a focused media activity")
        engine.send(.hideLiveActivity(id:"urgent"))
        await settle()
        engine.dismissActiveContent()
        await settle()
        expect(engine.visibleLiveActivities.count == 1 && engine.visibleLiveActivities[0].id == "timer", "dismissed media cannot remain in the secondary bubble")
        engine.restoreDismissedContent()
        await settle()
        expect(engine.visibleLiveActivities.count == 2 && engine.notchModel.liveActivityContent?.id == "music", "restoring media reconstructs the pair")
        engine.send(.showLiveActivity(FixtureActivity(id:"music",priority:10,prefersCompactPresentation:true)))
        expect(engine.visibleLiveActivities.count == 2, "updates cannot duplicate activity indicators")

        let closing = NotchEngine(animations:{ .balanced },hideDelay:0.03,queueDelay:0)
        closing.send(.showLiveActivity(FixtureActivity(id:"music",priority:10,prefersCompactPresentation:true)))
        closing.send(.showLiveActivity(FixtureActivity(id:"timer",priority:20)))
        await settle()
        closing.send(.selectLiveActivity(id:"timer"))
        await settle()
        closing.collapse()
        closing.send(.hideLiveActivity(id:"music"))
        closing.send(.hideLiveActivity(id:"timer"))
        await settle()
        expect(closing.notchModel.content == nil && closing.visibleLiveActivities.isEmpty, "ending both events during collapse must not resurrect a stale activity")
        print("PASS: \(passed) real live-activity engine checks")
    }
}
