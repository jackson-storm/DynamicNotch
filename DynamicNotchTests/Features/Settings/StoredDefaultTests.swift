//
//  StoredDefaultTests.swift
//  DynamicNotchTests
//

import XCTest
import Combine
@testable import DynamicNotch

@MainActor
final class StoredDefaultTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "DynamicNotch.Tests.StoredDefault.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: suiteName)
        testDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testCalendarSettingsStoreDefaults() {
        let store = CalendarSettingsStore(defaults: testDefaults)

        XCTAssertTrue(store.isCalendarLiveActivityEnabled)
        XCTAssertTrue(store.showAllDayEvents)
        XCTAssertEqual(store.daysToShow, 7)
        XCTAssertEqual(store.noticeMinutes, 15)
        XCTAssertEqual(store.includedCalendarIDs, [])
        XCTAssertEqual(store.timeDisplayFormat, .exact)
        XCTAssertEqual(store.ongoingEventHideMinutes, 0)
        XCTAssertFalse(store.isPrivacyModeEnabled)
        XCTAssertFalse(store.isSoundAlertEnabled)
    }

    func testCalendarSettingsStorePersistsChanges() {
        let store = CalendarSettingsStore(defaults: testDefaults)

        store.daysToShow = 14
        store.isPrivacyModeEnabled = true
        store.timeDisplayFormat = .relative

        XCTAssertEqual(testDefaults.integer(forKey: GeneralSettingsStorage.Keys.calendarDaysToShow), 14)
        XCTAssertTrue(testDefaults.bool(forKey: GeneralSettingsStorage.Keys.calendarPrivacyMode))
        XCTAssertEqual(
            testDefaults.string(forKey: GeneralSettingsStorage.Keys.calendarTimeDisplayFormat),
            CalendarTimeDisplayFormat.relative.rawValue
        )

        // Create fresh store with same defaults to verify persistence
        let freshStore = CalendarSettingsStore(defaults: testDefaults)
        XCTAssertEqual(freshStore.daysToShow, 14)
        XCTAssertTrue(freshStore.isPrivacyModeEnabled)
        XCTAssertEqual(freshStore.timeDisplayFormat, .relative)
    }

    func testLockScreenFeatureSettingsStoreDefaults() {
        let store = LockScreenFeatureSettingsStore(defaults: testDefaults)

        XCTAssertTrue(store.isLockScreenLiveActivityEnabled)
        XCTAssertTrue(store.isLockScreenSoundEnabled)
        XCTAssertTrue(store.isLockScreenMediaPanelEnabled)
        XCTAssertEqual(store.lockScreenStyle, .compact)
        XCTAssertEqual(store.widgetAppearanceStyle, .ultraThinMaterial)
        XCTAssertEqual(store.widgetTintStyle, .neutral)
        XCTAssertEqual(store.mediaPanelVerticalOffset, 0.0)
    }

    func testLockScreenFeatureSettingsStorePersistsChanges() {
        let store = LockScreenFeatureSettingsStore(defaults: testDefaults)

        store.isLockScreenLiveActivityEnabled = false
        store.mediaPanelVerticalOffset = 25.5
        store.lockScreenStyle = .enlarged

        XCTAssertFalse(testDefaults.bool(forKey: LockScreenSettings.liveActivityKey))
        XCTAssertEqual(testDefaults.double(forKey: LockScreenSettings.mediaPanelVerticalOffsetKey), 25.5)
        XCTAssertEqual(
            testDefaults.string(forKey: LockScreenSettings.styleKey),
            LockScreenStyle.enlarged.rawValue
        )
    }

    func testObjectWillChangeFiresOnPropertyUpdate() {
        let store = CalendarSettingsStore(defaults: testDefaults)
        var changeCount = 0
        var cancellables = Set<AnyCancellable>()

        store.objectWillChange.sink {
            changeCount += 1
        }.store(in: &cancellables)

        XCTAssertEqual(changeCount, 0)
        store.daysToShow = 21
        XCTAssertEqual(changeCount, 1)
        store.isPrivacyModeEnabled = true
        XCTAssertEqual(changeCount, 2)
    }

    func testCustomUserDefaultsIsolation() {
        let suite1 = "DynamicNotch.Tests.Isolation1.\(UUID().uuidString)"
        let suite2 = "DynamicNotch.Tests.Isolation2.\(UUID().uuidString)"
        let defaults1 = UserDefaults(suiteName: suite1)!
        let defaults2 = UserDefaults(suiteName: suite2)!

        let store1 = CalendarSettingsStore(defaults: defaults1)
        let store2 = CalendarSettingsStore(defaults: defaults2)

        store1.daysToShow = 30
        XCTAssertEqual(store1.daysToShow, 30)
        XCTAssertEqual(store2.daysToShow, 7)

        defaults1.removePersistentDomain(forName: suite1)
        defaults2.removePersistentDomain(forName: suite2)
    }

    func testHUDSettingsStoreDefaultsAndClamping() {
        let store = HUDSettingsStore(defaults: testDefaults)

        XCTAssertTrue(store.isBrightnessHUDEnabled)
        XCTAssertEqual(store.brightnessHUDDuration, 2)
        XCTAssertEqual(store.hudStyle, .compact)
        XCTAssertEqual(store.indicatorTintStyle, .levelColor)

        store.brightnessHUDDuration = 100 // Should clamp to max duration (5)
        XCTAssertEqual(store.brightnessHUDDuration, 5)
        XCTAssertEqual(testDefaults.integer(forKey: GeneralSettingsStorage.Keys.brightnessHUDDuration), 5)

        store.hudStyle = .minimal
        XCTAssertEqual(testDefaults.string(forKey: GeneralSettingsStorage.Keys.hudStyle), HudStyle.minimal.rawValue)
    }

    func testBatterySettingsStoreDefaultsAndClamping() {
        let store = BatterySettingsStore(defaults: testDefaults)

        XCTAssertTrue(store.isChargerTemporaryActivityEnabled)
        XCTAssertEqual(store.chargerTemporaryActivityDuration, 4)
        XCTAssertEqual(store.lowPowerNotificationThreshold, 20)
        XCTAssertEqual(store.fullPowerNotificationThreshold, 100)
        XCTAssertEqual(store.lowPowerStyle, .standard)

        store.lowPowerNotificationThreshold = 2 // Should clamp to range 5...50
        XCTAssertEqual(store.lowPowerNotificationThreshold, 5)
        XCTAssertEqual(testDefaults.integer(forKey: GeneralSettingsStorage.Keys.lowPowerNotificationThreshold), 5)

        store.fullPowerNotificationThreshold = 150 // Should clamp to range 50...100
        XCTAssertEqual(store.fullPowerNotificationThreshold, 100)
    }

    func testApplicationSettingsStoreDefaultsAndClamping() {
        let store = ApplicationSettingsStore(defaults: testDefaults)

        XCTAssertFalse(store.isDockIconVisible)
        XCTAssertEqual(store.appearanceMode, .system)
        XCTAssertEqual(store.notchStrokeWidth, 1.5)
        XCTAssertEqual(store.notchStrokeOpacity, 1.0)
        XCTAssertEqual(store.notchAnimationPreset, .balanced)

        store.notchStrokeWidth = 5.0 // Range: 1.0...3.0
        XCTAssertEqual(store.notchStrokeWidth, 3.0)

        store.notchStrokeOpacity = 2.0 // Range: 0.0...1.0
        XCTAssertEqual(store.notchStrokeOpacity, 1.0)

        store.appearanceMode = .dark
        XCTAssertEqual(testDefaults.string(forKey: GeneralSettingsStorage.Keys.appearanceMode), SettingsAppearanceMode.dark.rawValue)
    }
}
