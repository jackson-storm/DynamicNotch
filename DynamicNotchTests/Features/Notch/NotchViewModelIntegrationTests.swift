import XCTest
import SwiftUI
@testable import DynamicNotch

final class NotchViewModelIntegrationTests: XCTestCase {
    @MainActor
    func testHigherPriorityLiveActivityReplacesLowerPriority() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "low", priority: 10)))
        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "low" }
        }

        viewModel.send(.showLiveActivity(TestNotchContent(id: "high", priority: 50)))
        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "high" }
        }
    }

    @MainActor
    func testTemporaryNotificationSuspendsAndRestoresLiveActivity() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "live", priority: 10)))
        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "live" }
        }

        viewModel.send(
            .showTemporaryNotification(
                TestNotchContent(id: "temporary", priority: 0),
                duration: 0.05
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.temporaryNotificationContent?.id == "temporary" }
        }

        await assertEventually(timeout: 1.5) {
            await MainActor.run {
                viewModel.notchModel.temporaryNotificationContent == nil &&
                viewModel.notchModel.liveActivityContent?.id == "live"
            }
        }
    }

    @MainActor
    func testTemporaryNotificationAppearsImmediatelyWhenNotchIsEmpty() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.5,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(
            .showTemporaryNotification(
                TestNotchContent(id: "hud", priority: 0),
                duration: .infinity
            )
        )

        await assertEventually(timeout: 0.15) {
            await MainActor.run { viewModel.notchModel.temporaryNotificationContent?.id == "hud" }
        }
    }

    @MainActor
    func testActivityPresentationHiddenCollapsesSurfaceWithoutClearingLiveActivity() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(
            .showLiveActivity(
                TestNotchContent(
                    id: "expandable",
                    priority: 10,
                    isExpandable: true,
                    expandedWidthOffset: 140,
                    expandedHeightOffset: 80
                )
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "expandable" }
        }

        viewModel.handleActiveContentTap()

        await assertEventually {
            await MainActor.run { viewModel.notchModel.isLiveActivityExpanded }
        }

        let expandedPresentedSize = await MainActor.run { viewModel.presentedNotchSize }

        viewModel.setActivityPresentationHidden(true)

        let hiddenState = await MainActor.run {
            (
                contentID: viewModel.notchModel.liveActivityContent?.id,
                isExpanded: viewModel.notchModel.isLiveActivityExpanded,
                presentedSize: viewModel.presentedNotchSize,
                baseWidth: viewModel.notchModel.baseWidth,
                baseHeight: viewModel.notchModel.baseHeight,
                canDismiss: viewModel.canDismissWithMouseDrag
            )
        }

        XCTAssertEqual(hiddenState.contentID, "expandable")
        XCTAssertTrue(hiddenState.isExpanded)
        XCTAssertEqual(hiddenState.presentedSize.width, hiddenState.baseWidth, accuracy: 0.001)
        XCTAssertEqual(hiddenState.presentedSize.height, hiddenState.baseHeight, accuracy: 0.001)
        XCTAssertFalse(hiddenState.canDismiss)

        viewModel.setActivityPresentationHidden(false)

        let restoredState = await MainActor.run {
            (
                contentID: viewModel.notchModel.liveActivityContent?.id,
                isExpanded: viewModel.notchModel.isLiveActivityExpanded,
                presentedSize: viewModel.presentedNotchSize
            )
        }

        XCTAssertEqual(restoredState.contentID, "expandable")
        XCTAssertTrue(restoredState.isExpanded)
        XCTAssertEqual(restoredState.presentedSize.width, expandedPresentedSize.width, accuracy: 0.001)
        XCTAssertEqual(restoredState.presentedSize.height, expandedPresentedSize.height, accuracy: 0.001)
    }

    @MainActor
    func testActivityPresentationHiddenKeepsProcessingLiveActivityUpdates() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "low", priority: 10)))

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "low" }
        }

        viewModel.setActivityPresentationHidden(true)
        viewModel.send(
            .showLiveActivity(
                TestNotchContent(
                    id: "high",
                    priority: 50,
                    collapsedWidthOffset: 60
                )
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "high" }
        }

        let hiddenPresentedSize = await MainActor.run {
            (
                presented: viewModel.presentedNotchSize,
                baseWidth: viewModel.notchModel.baseWidth,
                baseHeight: viewModel.notchModel.baseHeight
            )
        }

        XCTAssertEqual(hiddenPresentedSize.presented.width, hiddenPresentedSize.baseWidth, accuracy: 0.001)
        XCTAssertEqual(hiddenPresentedSize.presented.height, hiddenPresentedSize.baseHeight, accuracy: 0.001)

        viewModel.setActivityPresentationHidden(false)

        let restoredPresentedSize = await MainActor.run { viewModel.presentedNotchSize }

        XCTAssertGreaterThan(restoredPresentedSize.width, hiddenPresentedSize.baseWidth)
        XCTAssertEqual(restoredPresentedSize.height, hiddenPresentedSize.baseHeight, accuracy: 0.001)
    }

    @MainActor
    func testActivityPresentationHiddenKeepsTemporaryNotificationVisible() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "live", priority: 10)))
        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "live" }
        }

        viewModel.send(
            .showTemporaryNotification(
                TestNotchContent(
                    id: "temporary",
                    priority: 0,
                    collapsedWidthOffset: 80,
                    collapsedHeightOffset: 12
                ),
                duration: .infinity
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.temporaryNotificationContent?.id == "temporary" }
        }

        let visibleTemporarySize = await MainActor.run { viewModel.presentedNotchSize }

        viewModel.setActivityPresentationHidden(true)

        let hiddenState = await MainActor.run {
            (
                displayedContentID: viewModel.displayedContent?.id,
                presentedSize: viewModel.presentedNotchSize,
                baseWidth: viewModel.notchModel.baseWidth,
                baseHeight: viewModel.notchModel.baseHeight
            )
        }

        XCTAssertEqual(hiddenState.displayedContentID, "temporary")
        XCTAssertGreaterThan(hiddenState.presentedSize.width, hiddenState.baseWidth)
        XCTAssertGreaterThan(hiddenState.presentedSize.height, hiddenState.baseHeight)
        XCTAssertEqual(hiddenState.presentedSize.width, visibleTemporarySize.width, accuracy: 0.001)
        XCTAssertEqual(hiddenState.presentedSize.height, visibleTemporarySize.height, accuracy: 0.001)
    }

    @MainActor
    func testStrokeRemainsVisibleUntilCloseAnimationFinishes() async {
        let animations = NotchAnimations(
            contentUpdate: .linear(duration: 0.01),
            contentHide: .linear(duration: 0.01),
            contentShow: .linear(duration: 0.01),
            openContentTransition: .linear(duration: 0.01),
            expandLiveActivity: .linear(duration: 0.01),
            expandLiveActivityContentTransition: .linear(duration: 0.01),
            closeLiveActivity: .linear(duration: 0.01),
            closeLiveActivityContentTransition: .linear(duration: 0.01),
            stretchReset: .linear(duration: 0.01),
            strokeVisibility: .linear(duration: 0.01),
            notchVisibility: .linear(duration: 0.01),
            hideShowDelay: 0.01,
            queuePacingDelay: 0
        )

        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            animations: animations,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "live", priority: 10)))
        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "live" }
        }

        viewModel.handleStrokeVisibility()
        XCTAssertTrue(viewModel.showNotch)
        XCTAssertTrue(viewModel.shouldRenderStroke)

        viewModel.send(.hideLiveActivity(id: "live"))

        await assertEventually {
            await MainActor.run { viewModel.notchModel.content == nil }
        }

        viewModel.handleStrokeVisibility()
        XCTAssertTrue(viewModel.showNotch)
        XCTAssertTrue(viewModel.shouldRenderStroke)

        try? await Task.sleep(nanoseconds: 5_000_000)

        XCTAssertTrue(viewModel.showNotch)
        XCTAssertTrue(viewModel.shouldRenderStroke)

        await assertEventually(timeout: 1.0) {
            await MainActor.run {
                viewModel.showNotch == false && viewModel.shouldRenderStroke == false
            }
        }
    }

    @MainActor
    func testHoverExpandInteractionBecomesAvailableForExpandableLiveActivity() async {
        let hoverDelay: TimeInterval = 0.41
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(
                notchExpandInteraction: .hover,
                notchPressHoldDuration: hoverDelay
            ),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(
            .showLiveActivity(
                TestNotchContent(
                    id: "hover-expand",
                    priority: 10,
                    isExpandable: true,
                    expandedWidthOffset: 120,
                    expandedHeightOffset: 60
                )
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "hover-expand" }
        }

        let state = await MainActor.run {
            (
                hover: viewModel.shouldExpandActiveContentOnHover,
                click: viewModel.shouldExpandActiveContentOnClick,
                pressAndHold: viewModel.shouldExpandActiveContentOnPressAndHold,
                delay: viewModel.notchHoverExpandDelay
            )
        }

        XCTAssertTrue(state.hover)
        XCTAssertFalse(state.click)
        XCTAssertFalse(state.pressAndHold)
        XCTAssertEqual(state.delay, hoverDelay, accuracy: 0.001)
    }

    @MainActor
    func testHidingCurrentLiveActivityRestoresNextHighestPriorityActivity() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "low", priority: 10)))
        viewModel.send(.showLiveActivity(TestNotchContent(id: "high", priority: 50)))

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "high" }
        }

        viewModel.send(.hideLiveActivity(id: "high"))

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "low" }
        }
    }

    @MainActor
    func testDismissActiveContentHidesTemporaryNotificationAndRestoresLiveActivity() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "live", priority: 10)))
        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "live" }
        }

        viewModel.send(
            .showTemporaryNotification(
                TestNotchContent(id: "temporary", priority: 0),
                duration: .infinity
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.temporaryNotificationContent?.id == "temporary" }
        }

        viewModel.dismissActiveContent()

        await assertEventually {
            await MainActor.run {
                viewModel.notchModel.temporaryNotificationContent == nil &&
                viewModel.notchModel.liveActivityContent?.id == "live"
            }
        }
    }

    @MainActor
    func testDismissActiveContentRemovesVisibleLiveActivityAndShowsNextHighest() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "low", priority: 10)))
        viewModel.send(.showLiveActivity(TestNotchContent(id: "high", priority: 50)))

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "high" }
        }

        viewModel.dismissActiveContent()

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "low" }
        }
    }

    @MainActor
    func testDismissActiveContentCollapsesExpandedTimerInsteadOfHidingIt() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        let timerViewModel = TimerViewModel(monitor: InactiveClockTimerMonitor())
        let settingsViewModel = SettingsViewModel()
        TestLifetime.retain(viewModel)
        TestLifetime.retain(timerViewModel)
        TestLifetime.retain(settingsViewModel)

        viewModel.send(
            .showLiveActivity(
                TimerNotchContent(
                    timerViewModel: timerViewModel,
                    settingsViewModel: settingsViewModel
                )
            )
        )

        await assertEventually {
            await MainActor.run {
                viewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.timer.id
            }
        }

        viewModel.handleActiveContentTap()
        await assertEventually {
            await MainActor.run { viewModel.notchModel.isLiveActivityExpanded }
        }

        viewModel.dismissActiveContent()

        await assertEventually {
            await MainActor.run {
                viewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.timer.id &&
                !viewModel.notchModel.isLiveActivityExpanded
            }
        }
    }

    @MainActor
    func testRestoreDismissedContentBringsBackLastLiveActivity() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "low", priority: 10)))
        viewModel.send(.showLiveActivity(TestNotchContent(id: "high", priority: 50)))

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "high" }
        }

        viewModel.dismissActiveContent()

        await assertEventually {
            await MainActor.run {
                viewModel.notchModel.liveActivityContent?.id == "low" &&
                viewModel.canRestoreDismissedContent
            }
        }

        viewModel.restoreDismissedContent()

        await assertEventually {
            await MainActor.run {
                viewModel.notchModel.liveActivityContent?.id == "high" &&
                viewModel.canRestoreDismissedContent == false
            }
        }
    }

    @MainActor
    func testRestoreDismissedContentWalksBackThroughDismissedLiveActivityStack() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "low", priority: 10)))
        viewModel.send(.showLiveActivity(TestNotchContent(id: "mid", priority: 30)))
        viewModel.send(.showLiveActivity(TestNotchContent(id: "high", priority: 50)))

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "high" }
        }

        viewModel.dismissActiveContent()

        await assertEventually {
            await MainActor.run {
                viewModel.notchModel.liveActivityContent?.id == "mid" &&
                viewModel.canRestoreDismissedContent
            }
        }

        viewModel.dismissActiveContent()

        await assertEventually {
            await MainActor.run {
                viewModel.notchModel.liveActivityContent?.id == "low" &&
                viewModel.canRestoreDismissedContent
            }
        }

        viewModel.restoreDismissedContent()

        await assertEventually {
            await MainActor.run {
                viewModel.notchModel.liveActivityContent?.id == "mid" &&
                viewModel.canRestoreDismissedContent
            }
        }

        viewModel.restoreDismissedContent()

        await assertEventually {
            await MainActor.run {
                viewModel.notchModel.liveActivityContent?.id == "high" &&
                viewModel.canRestoreDismissedContent == false
            }
        }
    }

    @MainActor
    func testHidingDismissedLiveActivityRemovesItFromRestoreStack() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "low", priority: 10)))
        viewModel.send(.showLiveActivity(TestNotchContent(id: "high", priority: 50)))

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "high" }
        }

        viewModel.dismissActiveContent()

        await assertEventually {
            await MainActor.run {
                viewModel.notchModel.liveActivityContent?.id == "low" &&
                viewModel.canRestoreDismissedContent
            }
        }

        viewModel.send(.hideLiveActivity(id: "high"))

        try? await Task.sleep(nanoseconds: 50_000_000)

        let canRestore = await MainActor.run { viewModel.canRestoreDismissedContent }
        XCTAssertFalse(canRestore)

        viewModel.restoreDismissedContent()

        try? await Task.sleep(nanoseconds: 50_000_000)

        let visibleID = await MainActor.run { viewModel.notchModel.liveActivityContent?.id }
        XCTAssertEqual(visibleID, "low")
    }

    @MainActor
    func testRestoreDismissedContentBringsBackLastTemporaryNotification() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "live", priority: 10)))
        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "live" }
        }

        viewModel.send(
            .showTemporaryNotification(
                TestNotchContent(id: "temporary", priority: 0),
                duration: .infinity
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.temporaryNotificationContent?.id == "temporary" }
        }

        viewModel.dismissActiveContent()

        await assertEventually {
            await MainActor.run {
                viewModel.notchModel.temporaryNotificationContent == nil &&
                viewModel.notchModel.liveActivityContent?.id == "live" &&
                viewModel.canRestoreDismissedContent
            }
        }

        viewModel.restoreDismissedContent()

        await assertEventually {
            await MainActor.run {
                viewModel.notchModel.temporaryNotificationContent?.id == "temporary" &&
                viewModel.canRestoreDismissedContent == false
            }
        }
    }

    @MainActor
    func testDuplicateTemporaryNotificationRestartsLifetimeInsteadOfUsingOldTimer() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(
            .showTemporaryNotification(
                TestNotchContent(id: "temporary", priority: 0),
                duration: 0.05
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.temporaryNotificationContent?.id == "temporary" }
        }

        try? await Task.sleep(nanoseconds: 30_000_000)

        viewModel.send(
            .showTemporaryNotification(
                TestNotchContent(id: "temporary", priority: 0),
                duration: 0.2
            )
        )

        try? await Task.sleep(nanoseconds: 80_000_000)

        let isStillVisible = await MainActor.run {
            viewModel.notchModel.temporaryNotificationContent?.id == "temporary"
        }
        XCTAssertTrue(isStillVisible, "The refreshed temporary notification should survive the old timer.")

        await assertEventually(timeout: 1.0) {
            await MainActor.run { viewModel.notchModel.temporaryNotificationContent == nil }
        }
    }

    @MainActor
    func testTappingExpandableLiveActivityUsesExpandedPresentation() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(
            .showLiveActivity(
                TestNotchContent(
                    id: "expandable",
                    priority: 10,
                    collapsedWidthOffset: 20,
                    isExpandable: true,
                    expandedWidthOffset: 140,
                    expandedHeightOffset: 80
                )
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "expandable" }
        }

        let collapsedSize = await MainActor.run { viewModel.notchModel.size }

        viewModel.handleActiveContentTap()
        await assertEventually {
            await MainActor.run { viewModel.notchModel.isLiveActivityExpanded }
        }
        let expandedSize = await MainActor.run { viewModel.notchModel.size }

        XCTAssertGreaterThan(expandedSize.width, collapsedSize.width)
        XCTAssertGreaterThan(expandedSize.height, collapsedSize.height)
    }

    @MainActor
    func testPresentedNotchSizeKeepsOpeningTransitionUnstaged() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(
            .showLiveActivity(
                TestNotchContent(
                    id: "expandable",
                    priority: 10,
                    isExpandable: true,
                    expandedWidthOffset: 140,
                    expandedHeightOffset: 90
                )
            )
        )
        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "expandable" }
        }

        let collapsedPresentedSize = await MainActor.run { viewModel.presentedNotchSize }

        viewModel.handleActiveContentTap()

        await assertEventually {
            await MainActor.run { viewModel.notchModel.isLiveActivityExpanded }
        }

        let presentedExpandedSize = await MainActor.run { viewModel.presentedNotchSize }
        let expandedSize = await MainActor.run { viewModel.notchModel.size }

        XCTAssertGreaterThan(presentedExpandedSize.width, collapsedPresentedSize.width)
        XCTAssertGreaterThan(presentedExpandedSize.height, collapsedPresentedSize.height)
        XCTAssertEqual(presentedExpandedSize.height, expandedSize.height, accuracy: 0.001)
    }

    @MainActor
    func testPresentedNotchSizeStagesHeightDuringClosingTransition() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.2,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(
            .showLiveActivity(
                TestNotchContent(
                    id: "expandable",
                    priority: 10,
                    isExpandable: true,
                    expandedWidthOffset: 140,
                    expandedHeightOffset: 90
                )
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "expandable" }
        }

        viewModel.handleActiveContentTap()
        await assertEventually {
            await MainActor.run { viewModel.notchModel.isLiveActivityExpanded }
        }
        let expandedSize = await MainActor.run { viewModel.notchModel.size }

        viewModel.handleOutsideClick()

        await assertEventually(timeout: 1.0) {
            await MainActor.run {
                let presentedSize = viewModel.presentedNotchSize
                let targetSize = viewModel.notchModel.size

                return presentedSize.width < expandedSize.width &&
                presentedSize.height < expandedSize.height &&
                presentedSize.height > targetSize.height
            }
        }

        await assertEventually(timeout: 1.0) {
            await MainActor.run {
                abs(viewModel.presentedNotchSize.height - viewModel.notchModel.size.height) < 0.001
            }
        }
    }

    @MainActor
    func testTappingNonExpandableLiveActivityKeepsCollapsedPresentation() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "static", priority: 10)))

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "static" }
        }

        let collapsedSize = await MainActor.run { viewModel.notchModel.size }

        viewModel.handleActiveContentTap()

        let isExpanded = await MainActor.run { viewModel.notchModel.isLiveActivityExpanded }
        let currentSize = await MainActor.run { viewModel.notchModel.size }

        XCTAssertFalse(isExpanded)
        XCTAssertEqual(currentSize.width, collapsedSize.width, accuracy: 0.001)
        XCTAssertEqual(currentSize.height, collapsedSize.height, accuracy: 0.001)
    }

    @MainActor
    func testTappingDownloadLiveActivityUsesExpandedPresentation() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        let settingsViewModel = SettingsViewModel()
        let downloadViewModel = DownloadViewModel(monitor: FakeFileDownloadMonitor())
        TestLifetime.retain(viewModel)
        TestLifetime.retain(downloadViewModel)

        viewModel.send(.showLiveActivity(DownloadNotchContent(downloadViewModel: downloadViewModel, settingsViewModel: settingsViewModel)))

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.download.id }
        }

        let collapsedSize = await MainActor.run { viewModel.notchModel.size }

        viewModel.handleActiveContentTap()
        await assertEventually {
            await MainActor.run { viewModel.notchModel.isLiveActivityExpanded }
        }
        let expandedSize = await MainActor.run { viewModel.notchModel.size }

        XCTAssertGreaterThan(expandedSize.height, collapsedSize.height)
    }

    @MainActor
    func testOutsideClickHidesExpandedLiveActivityThenRestoresCollapsedPresentation() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.05,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(
            .showLiveActivity(
                TestNotchContent(
                    id: "expandable",
                    priority: 10,
                    isExpandable: true,
                    expandedWidthOffset: 140,
                    expandedHeightOffset: 80
                )
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "expandable" }
        }

        viewModel.handleActiveContentTap()
        await assertEventually {
            await MainActor.run { viewModel.notchModel.isLiveActivityExpanded }
        }

        viewModel.handleOutsideClick()

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent == nil }
        }

        await assertEventually {
            await MainActor.run {
                viewModel.notchModel.liveActivityContent?.id == "expandable" &&
                !viewModel.notchModel.isLiveActivityExpanded
            }
        }
    }

    @MainActor
    func testOutsideClickDoesNotDismissTemporaryNotification() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "live", priority: 10)))

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "live" }
        }

        viewModel.send(
            .showTemporaryNotification(
                TestNotchContent(id: "temporary", priority: 0),
                duration: .infinity
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.temporaryNotificationContent?.id == "temporary" }
        }

        viewModel.handleOutsideClick()

        let temporaryID = await MainActor.run {
            viewModel.notchModel.temporaryNotificationContent?.id
        }
        let liveActivityID = await MainActor.run {
            viewModel.notchModel.liveActivityContent?.id
        }

        XCTAssertEqual(temporaryID, "temporary")
        XCTAssertNil(liveActivityID)
    }

    @MainActor
    func testTemporaryNotificationCollapsesExpandedLiveActivityBeforeRestore() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(
            .showLiveActivity(
                TestNotchContent(
                    id: "expandable",
                    priority: 10,
                    isExpandable: true,
                    expandedWidthOffset: 140,
                    expandedHeightOffset: 80
                )
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "expandable" }
        }

        viewModel.handleActiveContentTap()
        await assertEventually {
            await MainActor.run { viewModel.notchModel.isLiveActivityExpanded }
        }

        viewModel.send(
            .showTemporaryNotification(
                TestNotchContent(id: "temporary", priority: 0),
                duration: .infinity
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.temporaryNotificationContent?.id == "temporary" }
        }

        let isExpandedWhileTemporary = await MainActor.run {
            viewModel.notchModel.isLiveActivityExpanded
        }
        XCTAssertFalse(isExpandedWhileTemporary)

        viewModel.dismissActiveContent()

        await assertEventually {
            await MainActor.run {
                viewModel.notchModel.temporaryNotificationContent == nil &&
                viewModel.notchModel.liveActivityContent?.id == "expandable"
            }
        }

        let isExpandedAfterRestore = await MainActor.run {
            viewModel.notchModel.isLiveActivityExpanded
        }
        XCTAssertFalse(isExpandedAfterRestore)
    }

    @MainActor
    func testUpdateDimensionsAppliesSettingsOffsets() {
        let baseSettings = TestNotchSettings()
        let offsetSettings = TestNotchSettings(notchWidth: 7, notchHeight: 3)
        let screenMetricsProvider: (any NotchSettingsProviding) -> NotchScreenMetrics? = { _ in
            (width: 1440, topInset: 74, notchSize: CGSize(width: 190, height: 74))
        }

        let baseViewModel = NotchViewModel(
            settings: baseSettings,
            screenMetricsProvider: screenMetricsProvider
        )
        let offsetViewModel = NotchViewModel(
            settings: offsetSettings,
            screenMetricsProvider: screenMetricsProvider
        )
        TestLifetime.retain(baseViewModel)
        TestLifetime.retain(offsetViewModel)

        XCTAssertEqual(offsetViewModel.notchModel.baseWidth - baseViewModel.notchModel.baseWidth, 7, accuracy: 0.001)
        XCTAssertEqual(offsetViewModel.notchModel.baseHeight - baseViewModel.notchModel.baseHeight, 3, accuracy: 0.001)
    }

    @MainActor
    func testUpdateDimensionsUsesSelectedDisplayMetrics() {
        let settings = TestNotchSettings(displayLocation: .builtIn)
        let viewModel = NotchViewModel(
            settings: settings,
            screenMetricsProvider: { settings in
                switch settings.displayLocation {
                case .builtIn:
                    return (width: 1512, topInset: 74, notchSize: CGSize(width: 206, height: 37))
                case .main:
                    return (width: 1728, topInset: 0, notchSize: nil)
                case .specific:
                    return (width: 1600, topInset: 0, notchSize: nil)
                }
            }
        )
        TestLifetime.retain(viewModel)

        XCTAssertEqual(viewModel.notchModel.baseWidth, 220.7, accuracy: 0.001)
        XCTAssertEqual(viewModel.notchModel.baseHeight, 37, accuracy: 0.001)

        settings.displayLocation = .main
        viewModel.updateDimensions()

        let mainScale = max(0.35, CGFloat(1728) / 1440.0)
        XCTAssertEqual(viewModel.notchModel.baseWidth, 132.0, accuracy: 0.001)
        XCTAssertEqual(viewModel.notchModel.baseHeight, 27.0, accuracy: 0.001)
    }

    @MainActor
    func testUpdateDimensionsUsesSpecificDisplayMetrics() {
        let settings = TestNotchSettings(
            displayLocation: .specific,
            screenSelectionPreferences: NotchScreenSelectionPreferences(
                displayLocation: .specific,
                preferredDisplayUUID: "EXTERNAL",
                allowsAutomaticDisplaySwitching: false
            )
        )
        let viewModel = NotchViewModel(
            settings: settings,
            screenMetricsProvider: { settings in
                switch settings.screenSelectionPreferences.displayLocation {
                case .builtIn:
                    return (width: 1512, topInset: 74, notchSize: CGSize(width: 206, height: 37))
                case .main:
                    return (width: 1728, topInset: 0, notchSize: nil)
                case .specific:
                    return (width: 1920, topInset: 0, notchSize: nil)
                }
            }
        )
        TestLifetime.retain(viewModel)

        let scale = max(0.35, CGFloat(1920) / 1440.0)
        XCTAssertEqual(viewModel.notchModel.baseWidth, 146.667, accuracy: 0.01)
        XCTAssertEqual(viewModel.notchModel.baseHeight, 30.333, accuracy: 0.01)
    }

    @MainActor
    func testDismissSwipeCompressesCollapsedNotchAlongWidth() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(
            .showLiveActivity(
                TestNotchContent(
                    id: "collapsed",
                    priority: 10,
                    collapsedWidthOffset: 28,
                    collapsedHeightOffset: 8
                )
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "collapsed" }
        }

        let collapsedSize = await MainActor.run { viewModel.notchModel.size }

        viewModel.updateSwipeStretch(for: .dismiss, progress: 1)

        let interactiveSize = await MainActor.run { viewModel.interactiveNotchSize }
        let blurRadius = await MainActor.run { viewModel.contentResizeBlurRadius }
        let opacity = await MainActor.run { viewModel.contentResizeOpacity }

        XCTAssertLessThan(interactiveSize.width, collapsedSize.width)
        XCTAssertEqual(interactiveSize.height, collapsedSize.height, accuracy: 0.001)
        XCTAssertGreaterThan(blurRadius, 0)
        XCTAssertLessThan(opacity, 1)
    }

    @MainActor
    func testDismissSwipeCompressesExpandedNotchAlongHeight() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(
            .showLiveActivity(
                TestNotchContent(
                    id: "expanded",
                    priority: 10,
                    isExpandable: true,
                    expandedWidthOffset: 140,
                    expandedHeightOffset: 80
                )
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "expanded" }
        }

        viewModel.handleActiveContentTap()

        await assertEventually {
            await MainActor.run { viewModel.notchModel.isLiveActivityExpanded }
        }

        let expandedSize = await MainActor.run { viewModel.notchModel.size }

        viewModel.updateSwipeStretch(for: .dismiss, progress: 1)

        let baseCornerRadius = await MainActor.run { viewModel.notchModel.cornerRadius }
        let interactiveSize = await MainActor.run { viewModel.interactiveNotchSize }
        let interactiveCornerRadius = await MainActor.run { viewModel.interactiveCornerRadius }
        let blurRadius = await MainActor.run { viewModel.contentResizeBlurRadius }
        let opacity = await MainActor.run { viewModel.contentResizeOpacity }

        XCTAssertGreaterThan(interactiveSize.width, expandedSize.width)
        XCTAssertLessThan(interactiveSize.height, expandedSize.height)
        XCTAssertLessThan(interactiveCornerRadius.top, baseCornerRadius.top)
        XCTAssertGreaterThan(blurRadius, 0)
        XCTAssertLessThan(opacity, 1)
    }

    @MainActor
    func testTapToExpandSettingBlocksExpansion() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(isNotchTapToExpandEnabled: false),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(
            .showLiveActivity(
                TestNotchContent(
                    id: "expandable",
                    priority: 10,
                    isExpandable: true,
                    expandedWidthOffset: 140,
                    expandedHeightOffset: 80
                )
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "expandable" }
        }

        viewModel.handleActiveContentTap()

        let isExpanded = await MainActor.run { viewModel.notchModel.isLiveActivityExpanded }
        XCTAssertFalse(isExpanded)
    }

    @MainActor
    func testUpdateDimensionsSetsTopInset() {
        let settings = TestNotchSettings()
        let viewModel = NotchViewModel(
            settings: settings,
            screenMetricsProvider: { _ in
                (width: 1440, topInset: 42, notchSize: nil)
            }
        )
        TestLifetime.retain(viewModel)

        XCTAssertEqual(viewModel.topInset, 42, accuracy: 0.001)

        let viewModelNoNotch = NotchViewModel(
            settings: settings,
            screenMetricsProvider: { _ in
                (width: 1440, topInset: 0, notchSize: nil)
            }
        )
        TestLifetime.retain(viewModelNoNotch)

        XCTAssertEqual(viewModelNoNotch.topInset, 0, accuracy: 0.001)
    }

    @MainActor
    func testDynamicIslandCornerRadiusCoefficients() async {
        let settings = TestNotchSettings()
        let viewModel = NotchViewModel(
            settings: settings,
            hideDelay: 0.05,
            queueDelay: 0,
            screenMetricsProvider: { _ in
                (width: 1440, topInset: 0, notchSize: nil)
            }
        )
        TestLifetime.retain(viewModel)

        // 1. In collapsed state, should be height * 0.5
        let (collapsedRadius, collapsedHeight) = await MainActor.run {
            (viewModel.dynamicIslandCornerRadius, viewModel.presentedNotchSize.height)
        }
        XCTAssertEqual(collapsedRadius, collapsedHeight * 0.5, accuracy: 0.001)

        // Send expandable content and expand it
        viewModel.send(
            .showLiveActivity(
                TestNotchContent(
                    id: "expandable",
                    priority: 10,
                    isExpandable: true,
                    expandedWidthOffset: 140,
                    expandedHeightOffset: 80
                )
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "expandable" }
        }

        viewModel.handleActiveContentTap()

        await assertEventually {
            await MainActor.run { viewModel.isDisplayingExpandedLiveActivity }
        }

        // 2. In expanded state, should be height * 0.2
        let (expandedRadius, expandedHeight) = await MainActor.run {
            (viewModel.dynamicIslandCornerRadius, viewModel.presentedNotchSize.height)
        }
        XCTAssertEqual(expandedRadius, expandedHeight * 0.2, accuracy: 0.001)
    }

    @MainActor
    func testRestoreSwipeIncreasesTopAndBottomCornerRadius() async {
        let settings = TestNotchSettings()
        let viewModel = NotchViewModel(
            settings: settings,
            hideDelay: 0.05,
            queueDelay: 0,
            screenMetricsProvider: { _ in
                (width: 1440, topInset: 74, notchSize: CGSize(width: 190, height: 74))
            }
        )
        TestLifetime.retain(viewModel)

        // Send taller and wider live activity:
        // width excess = 95, baseWidth = 190 -> widthFactor = 0.5
        viewModel.send(
            .showLiveActivity(
                TestNotchContent(
                    id: "tallerAndWiderContent",
                    priority: 10,
                    collapsedWidthOffset: 95,
                    collapsedHeightOffset: 10
                )
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "tallerAndWiderContent" }
        }

        let initialRadius = viewModel.interactiveCornerRadius

        viewModel.updateSwipeStretch(for: .restore, progress: 1.0)

        let expectedProgress: CGFloat = 1.0
        let widthFactor = (viewModel.notchModel.size.width - viewModel.notchModel.baseWidth) / viewModel.notchModel.baseWidth
        let expectedRadiusTop = initialRadius.top + (SwipeFeedbackMetrics.restoreTopCornerRadiusExpansion * expectedProgress * widthFactor)
        let expectedRadiusBottom = initialRadius.bottom + (SwipeFeedbackMetrics.restoreCornerRadiusExpansion * expectedProgress)

        let newRadius = viewModel.interactiveCornerRadius
        XCTAssertEqual(newRadius.top, expectedRadiusTop, accuracy: 0.001)
        XCTAssertEqual(newRadius.bottom, expectedRadiusBottom, accuracy: 0.001)
    }

    @MainActor
    func testRestoreSwipeDoesNotIncreaseTopCornerRadiusIfAtBaseWidth() async {
        let settings = TestNotchSettings()
        let viewModel = NotchViewModel(
            settings: settings,
            hideDelay: 0.05,
            queueDelay: 0,
            screenMetricsProvider: { _ in
                (width: 1440, topInset: 74, notchSize: CGSize(width: 190, height: 74))
            }
        )
        TestLifetime.retain(viewModel)

        // Taller but NOT wider content (widthOffset = 0, so width == baseWidth)
        viewModel.send(
            .showLiveActivity(
                TestNotchContent(
                    id: "tallerContent",
                    priority: 10,
                    collapsedWidthOffset: 0,
                    collapsedHeightOffset: 10
                )
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "tallerContent" }
        }

        let initialRadius = viewModel.interactiveCornerRadius

        viewModel.updateSwipeStretch(for: .restore, progress: 1.0)

        let expectedProgress: CGFloat = 1.0
        let expectedRadiusBottom = initialRadius.bottom + (4.0 * expectedProgress)

        let newRadius = viewModel.interactiveCornerRadius
        XCTAssertEqual(newRadius.top, initialRadius.top, accuracy: 0.001)
        XCTAssertEqual(newRadius.bottom, expectedRadiusBottom, accuracy: 0.001)
    }

    @MainActor
    func testRestoreSwipeDoesNotIncreaseTopCornerRadiusIfAtBaseHeight() async {
        let settings = TestNotchSettings()
        let viewModel = NotchViewModel(
            settings: settings,
            hideDelay: 0.05,
            queueDelay: 0,
            screenMetricsProvider: { _ in
                (width: 1440, topInset: 74, notchSize: CGSize(width: 190, height: 74))
            }
        )
        TestLifetime.retain(viewModel)

        // Wider but NOT taller content (heightOffset = 0, so height == baseHeight)
        viewModel.send(
            .showLiveActivity(
                TestNotchContent(
                    id: "widerContent",
                    priority: 10,
                    collapsedWidthOffset: 95,
                    collapsedHeightOffset: 0
                )
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "widerContent" }
        }

        let initialRadius = viewModel.interactiveCornerRadius

        viewModel.updateSwipeStretch(for: .restore, progress: 1.0)

        let expectedProgress: CGFloat = 1.0
        let expectedRadiusBottom = initialRadius.bottom + (4.0 * expectedProgress)

        let newRadius = viewModel.interactiveCornerRadius
        XCTAssertEqual(newRadius.top, initialRadius.top, accuracy: 0.001)
        XCTAssertEqual(newRadius.bottom, expectedRadiusBottom, accuracy: 0.001)
    }
}
