import XCTest
import Combine
@testable import DynamicNotch

@MainActor
final class PowerViewModelTests: XCTestCase {

    private func makeViewModel(
        onACPower: Bool = false,
        batteryLevel: Int = 50,
        lowPowerThreshold: Int = 20,
        fullPowerThreshold: Int = 80
    ) -> (PowerViewModel, FakePowerStateProvider, BatterySettingsStore) {
        let suiteName = "PowerViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settings = BatterySettingsStore(defaults: defaults)
        settings.lowPowerNotificationThreshold = lowPowerThreshold
        settings.fullPowerNotificationThreshold = fullPowerThreshold

        let provider = FakePowerStateProvider(onACPower: onACPower, batteryLevel: batteryLevel)
        let viewModel = PowerViewModel(powerService: provider, batterySettings: settings)

        return (viewModel, provider, settings)
    }

    func testConnectingChargerEmitsChargerEvent() {
        let (viewModel, provider, _) = makeViewModel(onACPower: false, batteryLevel: 50)
        XCTAssertNil(viewModel.event)

        provider.onACPower = true
        XCTAssertEqual(viewModel.event, .charger)
    }

    func testDisconnectingChargerDoesNotEmitChargerEvent() {
        let (viewModel, provider, _) = makeViewModel(onACPower: true, batteryLevel: 50)
        XCTAssertNil(viewModel.event)

        provider.onACPower = false
        XCTAssertNil(viewModel.event)
    }

    func testDroppingBelowLowPowerThresholdEmitsLowPowerEvent() {
        let (viewModel, provider, _) = makeViewModel(onACPower: false, batteryLevel: 25, lowPowerThreshold: 20)
        XCTAssertNil(viewModel.event)

        provider.batteryLevel = 19
        XCTAssertEqual(viewModel.event, .lowPower)
    }

    func testBatteryReachingExactLowPowerThresholdEmitsLowPowerEvent() {
        let (viewModel, provider, _) = makeViewModel(onACPower: false, batteryLevel: 21, lowPowerThreshold: 20)
        XCTAssertNil(viewModel.event)

        provider.batteryLevel = 20
        XCTAssertEqual(viewModel.event, .lowPower)
    }

    func testStayingBelowLowPowerThresholdDoesNotEmitDuplicateEvent() {
        let (viewModel, provider, _) = makeViewModel(onACPower: false, batteryLevel: 25, lowPowerThreshold: 20)
        provider.batteryLevel = 19
        XCTAssertEqual(viewModel.event, .lowPower)

        viewModel.event = nil
        provider.batteryLevel = 18
        XCTAssertNil(viewModel.event)
    }

    func testRisingAboveFullPowerThresholdEmitsFullPowerEvent() {
        let (viewModel, provider, _) = makeViewModel(onACPower: true, batteryLevel: 75, fullPowerThreshold: 80)
        XCTAssertNil(viewModel.event)

        provider.batteryLevel = 80
        XCTAssertEqual(viewModel.event, .fullPower)
    }

    func testStayingAboveFullPowerThresholdDoesNotEmitDuplicateEvent() {
        let (viewModel, provider, _) = makeViewModel(onACPower: true, batteryLevel: 75, fullPowerThreshold: 80)
        provider.batteryLevel = 80
        XCTAssertEqual(viewModel.event, .fullPower)

        viewModel.event = nil
        provider.batteryLevel = 85
        XCTAssertNil(viewModel.event)
    }

    func testUpdatingLowPowerThresholdDynamicallyAffectsEventTrigger() {
        let (viewModel, provider, settings) = makeViewModel(onACPower: false, batteryLevel: 35, lowPowerThreshold: 20)

        // Change threshold to 30
        settings.lowPowerNotificationThreshold = 30

        // Battery level drops to 28 (which is below the new threshold 30)
        provider.batteryLevel = 28
        XCTAssertEqual(viewModel.event, .lowPower)
    }

    func testUpdatingFullPowerThresholdDynamicallyAffectsEventTrigger() {
        let (viewModel, provider, settings) = makeViewModel(onACPower: true, batteryLevel: 82, fullPowerThreshold: 85)

        // Change threshold to 90
        settings.fullPowerNotificationThreshold = 90

        // Battery level rises to 88 (not yet 90)
        provider.batteryLevel = 88
        XCTAssertNil(viewModel.event)

        // Battery level rises to 90 (meets new threshold)
        provider.batteryLevel = 90
        XCTAssertEqual(viewModel.event, .fullPower)
    }
}
