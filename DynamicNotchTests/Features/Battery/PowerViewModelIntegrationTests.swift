import XCTest
@testable import DynamicNotch

@MainActor
final class PowerViewModelIntegrationTests: XCTestCase {
    func testInitialStateDoesNotEmitEvent() {
        let provider = FakePowerStateProvider(onACPower: true, batteryLevel: 15)
        let viewModel = PowerViewModel(powerService: provider)
        TestLifetime.retain(viewModel)

        XCTAssertNil(viewModel.event)
    }

    func testEmitsChargerEventOnlyOnTransitionToACPower() {
        let provider = FakePowerStateProvider(onACPower: false, batteryLevel: 60)
        let viewModel = PowerViewModel(powerService: provider)
        TestLifetime.retain(viewModel)

        provider.onACPower = true
        XCTAssertEqual(viewModel.event, .charger)

        viewModel.event = nil
        provider.onACPower = true
        XCTAssertNil(viewModel.event)
    }

    func testEmitsLowPowerOnlyWhenCrossingThreshold() {
        let provider = FakePowerStateProvider(onACPower: false, batteryLevel: 21)
        let viewModel = PowerViewModel(powerService: provider)
        TestLifetime.retain(viewModel)

        provider.batteryLevel = 20
        XCTAssertEqual(viewModel.event, .lowPower)

        viewModel.event = nil
        provider.batteryLevel = 19
        XCTAssertNil(viewModel.event)
    }

    func testEmitsFullPowerWhenBatteryReachesOneHundredPercent() {
        let provider = FakePowerStateProvider(onACPower: false, batteryLevel: 99)
        let viewModel = PowerViewModel(powerService: provider)
        TestLifetime.retain(viewModel)

        provider.batteryLevel = 100
        XCTAssertEqual(viewModel.event, .fullPower)
    }
}
