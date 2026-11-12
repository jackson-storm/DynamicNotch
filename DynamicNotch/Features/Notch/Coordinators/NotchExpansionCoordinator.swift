//
//  NotchExpansionCoordinator.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 11/10/26.
//

import SwiftUI
import Combine

@MainActor
final class NotchExpansionCoordinator: ObservableObject {
    enum Timing {
        static let preparationDelay: UInt64 = 16_000_000
        static let resetDelay: UInt64 = 120_000_000
    }

    @Published private(set) var isExpandingLiveActivityTransition = false

    private var expansionTransitionTask: Task<Void, Never>?

    func canExpandActiveLiveActivity(
        isActivityPresentationHidden: Bool,
        isLocked: Bool,
        hasTemporaryNotification: Bool,
        liveActivityId: String?,
        hasRealDisplayedContent: Bool,
        engineCanExpand: Bool
    ) -> Bool {
        guard (!isActivityPresentationHidden || isLocked) || hasTemporaryNotification else { return false }
        if isLocked {
            guard hasTemporaryNotification || liveActivityId == NotchContentRegistry.LockScreen.activity.id else {
                return false
            }
        }
        guard hasRealDisplayedContent else { return false }
        return engineCanExpand
    }

    func shouldExpandOnClick(
        isTapToExpandEnabled: Bool,
        expandInteraction: NotchExpandInteraction,
        canExpand: Bool
    ) -> Bool {
        isTapToExpandEnabled && expandInteraction == .click && canExpand
    }

    func shouldExpandOnPressAndHold(
        isTapToExpandEnabled: Bool,
        expandInteraction: NotchExpandInteraction,
        canExpand: Bool
    ) -> Bool {
        isTapToExpandEnabled && expandInteraction == .pressAndHold && canExpand
    }

    func shouldExpandOnHover(
        isTapToExpandEnabled: Bool,
        expandInteraction: NotchExpandInteraction,
        canExpand: Bool
    ) -> Bool {
        isTapToExpandEnabled && expandInteraction == .hover && canExpand
    }

    func shouldCollapseOnHoverLeaves(
        collapseInteraction: NotchCollapseInteraction,
        isDisplayingExpandedLiveActivity: Bool
    ) -> Bool {
        collapseInteraction == .hoverLeaves && isDisplayingExpandedLiveActivity
    }

    func performExpansion(triggerEngineAction: @escaping @MainActor () -> Void) {
        expansionTransitionTask?.cancel()
        isExpandingLiveActivityTransition = true

        expansionTransitionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: Timing.preparationDelay)
            guard let self, !Task.isCancelled else { return }

            triggerEngineAction()

            try? await Task.sleep(nanoseconds: Timing.resetDelay)
            guard !Task.isCancelled else { return }

            self.isExpandingLiveActivityTransition = false
            self.expansionTransitionTask = nil
        }
    }

    func cancel() {
        expansionTransitionTask?.cancel()
        expansionTransitionTask = nil
        isExpandingLiveActivityTransition = false
    }
}
