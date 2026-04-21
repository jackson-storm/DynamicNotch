import XCTest
import AppKit
import CoreAudio
@testable import DynamicNotch

@MainActor
final class NowPlayingViewModelIntegrationTests: XCTestCase {
    func testPublishesStartedAndStoppedEventsWhenSessionLifecycleChanges() {
        let service = FakeNowPlayingService()
        let viewModel = NowPlayingViewModel(service: service)
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()

        XCTAssertEqual(service.startCalls, 1)
        XCTAssertNil(viewModel.snapshot)

        let snapshot = makeNowPlayingSnapshot()
        service.publish(snapshot)

        XCTAssertEqual(viewModel.snapshot, snapshot)
        XCTAssertEqual(viewModel.event, .started)
        XCTAssertTrue(viewModel.hasActiveSession)

        service.publish(nil)

        XCTAssertEqual(viewModel.snapshot, snapshot)
        XCTAssertEqual(viewModel.event, .started)
        XCTAssertTrue(viewModel.hasActiveSession)

        RunLoop.main.run(until: Date().addingTimeInterval(0.8))

        XCTAssertNil(viewModel.snapshot)
        XCTAssertEqual(viewModel.event, .stopped)
        XCTAssertFalse(viewModel.hasActiveSession)
    }

    func testPlaybackControlsSendCommandsToService() {
        let service = FakeNowPlayingService()
        let viewModel = NowPlayingViewModel(service: service)
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()

        viewModel.previousTrack()
        viewModel.togglePlayPause()
        viewModel.nextTrack()

        XCTAssertEqual(
            service.commands,
            [.previousTrack, .togglePlayPause, .nextTrack]
        )
    }

    func testTogglePlayPauseUpdatesCurrentSnapshotImmediately() {
        let service = FakeNowPlayingService()
        let viewModel = NowPlayingViewModel(service: service)
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()

        service.publish(makeNowPlayingSnapshot(elapsedTime: 42, playbackRate: 1))

        viewModel.togglePlayPause()

        XCTAssertEqual(service.commands, [.togglePlayPause])
        XCTAssertEqual(viewModel.snapshot?.playbackRate, 0)
        XCTAssertFalse(viewModel.snapshot?.isPlaying ?? true)
    }

    func testPlaybackStateChangesPublishPlaybackStateEvent() {
        let service = FakeNowPlayingService()
        let viewModel = NowPlayingViewModel(service: service)
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()

        service.publish(makeNowPlayingSnapshot(playbackRate: 1))
        XCTAssertEqual(viewModel.event, .started)

        service.publish(makeNowPlayingSnapshot(playbackRate: 0))
        XCTAssertEqual(viewModel.event, .playbackStateChanged(isPlaying: false))

        service.publish(makeNowPlayingSnapshot(playbackRate: 1))
        XCTAssertEqual(viewModel.event, .playbackStateChanged(isPlaying: true))
    }

    func testSeekUpdatesCurrentSnapshotImmediately() {
        let service = FakeNowPlayingService()
        let viewModel = NowPlayingViewModel(service: service)
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()

        service.publish(makeNowPlayingSnapshot(duration: 243, elapsedTime: 42, playbackRate: 1))

        viewModel.seek(to: 120)

        XCTAssertEqual(service.commands, [.seek(120)])
        XCTAssertEqual(viewModel.snapshot?.elapsedTime, 120)
        XCTAssertEqual(viewModel.snapshot?.duration, 243)
        XCTAssertEqual(viewModel.snapshot?.playbackRate, 1)
    }

    func testArtworkPaletteUpdatesFromArtworkData() {
        let service = FakeNowPlayingService()
        let viewModel = NowPlayingViewModel(service: service)
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()

        service.publish(
            makeNowPlayingSnapshot(
                artworkData: makeArtworkData(color: NSColor(calibratedRed: 0.98, green: 0.49, blue: 0.12, alpha: 1))
            )
        )

        let components = rgbaComponents(from: viewModel.artworkPalette.equalizerBaseColor)
        XCTAssertGreaterThan(components.red, components.green)
        XCTAssertGreaterThan(components.green, components.blue)
        XCTAssertNotEqual(viewModel.artworkPalette, .fallback)
    }

    func testArtworkPersistsWhileActiveSnapshotTemporarilyLosesArtwork() {
        let service = FakeNowPlayingService()
        let viewModel = NowPlayingViewModel(service: service)
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()

        service.publish(makeNowPlayingSnapshot(artworkData: makeArtworkData(color: .systemBlue)))
        XCTAssertNotNil(viewModel.artworkImage)
        XCTAssertNotEqual(viewModel.artworkPalette, .fallback)

        service.publish(makeNowPlayingSnapshot(artworkData: nil))

        XCTAssertNotNil(viewModel.artworkImage)
        XCTAssertNotEqual(viewModel.artworkPalette, .fallback)
    }

    func testArtworkClearsWhenSessionStops() {
        let service = FakeNowPlayingService()
        let viewModel = NowPlayingViewModel(service: service)
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()

        service.publish(makeNowPlayingSnapshot(artworkData: makeArtworkData(color: .systemBlue)))
        XCTAssertNotNil(viewModel.artworkImage)
        XCTAssertNotEqual(viewModel.artworkPalette, .fallback)

        service.publish(nil)

        XCTAssertNotNil(viewModel.artworkImage)
        XCTAssertNotEqual(viewModel.artworkPalette, .fallback)

        RunLoop.main.run(until: Date().addingTimeInterval(0.8))

        XCTAssertNil(viewModel.artworkImage)
        XCTAssertEqual(viewModel.artworkPalette, .fallback)
    }

    func testTrackChangeTriggersArtworkFlipAndDelaysArtworkSwap() async throws {
        let service = FakeNowPlayingService()
        let viewModel = NowPlayingViewModel(service: service)
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()

        service.publish(
            makeNowPlayingSnapshot(
                title: "Midnight Echoes",
                artist: "Debug Ensemble",
                album: "Preview Mode",
                artworkData: makeArtworkData(color: .systemRed)
            )
        )

        let firstArtworkImage = try XCTUnwrap(viewModel.artworkImage)
        XCTAssertEqual(viewModel.artworkFlipAngle, 0)

        service.publish(nil)

        XCTAssertEqual(viewModel.snapshot?.title, "Midnight Echoes")
        XCTAssertTrue(viewModel.artworkImage === firstArtworkImage)

        service.publish(
            makeNowPlayingSnapshot(
                title: "Second Signal",
                artist: "Debug Ensemble",
                album: "Preview Mode",
                artworkData: makeArtworkData(color: .systemBlue)
            )
        )

        XCTAssertEqual(viewModel.artworkFlipAngle, 180)
        XCTAssertTrue(viewModel.artworkImage === firstArtworkImage)

        try? await Task.sleep(nanoseconds: 550_000_000)
        await Task.yield()

        XCTAssertFalse(viewModel.artworkImage === firstArtworkImage)
        XCTAssertNotEqual(viewModel.artworkPalette, .fallback)
    }

    func testAudioOutputRoutesLoadFromRoutingService() {
        let service = FakeNowPlayingService()
        let audioOutputRouting = FakeAudioOutputRoutingService(
            routes: [
                AudioOutputRoute(
                    id: 1,
                    name: "MacBook Pro Speakers",
                    transportType: kAudioDeviceTransportTypeBuiltIn,
                    isCurrent: true
                ),
                AudioOutputRoute(
                    id: 2,
                    name: "AirPods Pro",
                    transportType: kAudioDeviceTransportTypeBluetooth,
                    isCurrent: false
                )
            ]
        )
        let viewModel = NowPlayingViewModel(
            service: service,
            audioOutputRouting: audioOutputRouting
        )
        TestLifetime.retain(viewModel)

        XCTAssertEqual(viewModel.audioOutputRoutes.count, 2)
        XCTAssertEqual(viewModel.currentAudioOutputRoute?.name, "MacBook Pro Speakers")
    }

    func testSwitchAudioOutputDelegatesToRoutingServiceAndRefreshesCurrentRoute() {
        let service = FakeNowPlayingService()
        let audioOutputRouting = FakeAudioOutputRoutingService(
            routes: [
                AudioOutputRoute(
                    id: 1,
                    name: "MacBook Pro Speakers",
                    transportType: kAudioDeviceTransportTypeBuiltIn,
                    isCurrent: true
                ),
                AudioOutputRoute(
                    id: 2,
                    name: "AirPods Pro",
                    transportType: kAudioDeviceTransportTypeBluetooth,
                    isCurrent: false
                )
            ]
        )
        let viewModel = NowPlayingViewModel(
            service: service,
            audioOutputRouting: audioOutputRouting
        )
        TestLifetime.retain(viewModel)

        let targetRoute = audioOutputRouting.routes[1]
        viewModel.switchAudioOutput(to: targetRoute)

        XCTAssertEqual(audioOutputRouting.selectedRouteIDs, [2])
        XCTAssertEqual(viewModel.currentAudioOutputRoute?.name, "AirPods Pro")
        XCTAssertEqual(viewModel.audioOutputRoutes.first(where: { $0.id == 2 })?.isCurrent, true)
    }

    func testFavoriteStatePersistsForTrackIdentity() {
        let service = FakeNowPlayingService()
        let favoritesStore = makeFavoriteStore(named: #function)
        let viewModel = NowPlayingViewModel(
            service: service,
            favoritesStore: favoritesStore
        )
        TestLifetime.retain(viewModel)

        let snapshot = makeNowPlayingSnapshot(
            title: "Midnight Echoes",
            artist: "Debug Ensemble",
            album: "Preview Mode"
        )
        service.publish(snapshot)

        XCTAssertFalse(viewModel.isCurrentTrackFavorite)

        viewModel.toggleFavorite()
        XCTAssertTrue(viewModel.isCurrentTrackFavorite)

        let restoredService = FakeNowPlayingService()
        let restoredViewModel = NowPlayingViewModel(
            service: restoredService,
            favoritesStore: favoritesStore
        )
        TestLifetime.retain(restoredViewModel)
        restoredViewModel.startMonitoring()
        restoredService.publish(snapshot)

        XCTAssertTrue(restoredViewModel.isCurrentTrackFavorite)
    }

    func testFavoriteStateResetsForDifferentTrack() {
        let service = FakeNowPlayingService()
        let favoritesStore = makeFavoriteStore(named: #function)
        let viewModel = NowPlayingViewModel(
            service: service,
            favoritesStore: favoritesStore
        )
        TestLifetime.retain(viewModel)

        service.publish(
            makeNowPlayingSnapshot(
                title: "Midnight Echoes",
                artist: "Debug Ensemble",
                album: "Preview Mode"
            )
        )
        viewModel.toggleFavorite()
        XCTAssertTrue(viewModel.isCurrentTrackFavorite)

        service.publish(
            makeNowPlayingSnapshot(
                title: "Second Signal",
                artist: "Debug Ensemble",
                album: "Preview Mode"
            )
        )

        XCTAssertFalse(viewModel.isCurrentTrackFavorite)
    }
}

private func makeArtworkData(
    color: NSColor,
    size: CGSize = CGSize(width: 20, height: 20)
) -> Data {
    let width = Int(size.width)
    let height = Int(size.height)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    color.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:])!
}

private func rgbaComponents(from color: NSColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
    let resolvedColor = color.usingColorSpace(.sRGB) ?? color
    return (
        resolvedColor.redComponent,
        resolvedColor.greenComponent,
        resolvedColor.blueComponent,
        resolvedColor.alphaComponent
    )
}

private func makeFavoriteStore(named name: String) -> UserDefaults {
    let suiteName = "DynamicNotchTests.\(name)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}
