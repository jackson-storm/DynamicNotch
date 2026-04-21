internal import AppKit
import Accelerate
import Combine
import CoreAudio
import CoreMedia
#if canImport(ApplicationServices)
import ApplicationServices
#endif
#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif
import SwiftUI

@MainActor
final class NowPlayingViewModel: ObservableObject {
    private static let favoriteTrackKeysStorageKey = "settings.nowPlaying.favoriteTrackKeys"

    @Published private(set) var snapshot: NowPlayingSnapshot?
    @Published private(set) var artworkImage: NSImage?
    @Published private(set) var artworkPalette = NowPlayingArtworkPalette.fallback
    @Published private(set) var artworkFlipAngle: Double = 0
    @Published private(set) var audioOutputRoutes: [AudioOutputRoute] = []
    @Published private(set) var currentAudioOutputRoute: AudioOutputRoute?
    @Published private(set) var isCurrentTrackFavorite = false
    @Published private(set) var audioReactiveLevels = Array(repeating: CGFloat(0), count: 5)
    @Published var event: NowPlayingEvent?

    private var service: any NowPlayingMonitoring
    private let audioOutputRouting: any AudioOutputRouting
    private let favoritesStore: UserDefaults
    private let mediaSettings: MediaAndFilesSettingsStore
    private let audioLevelMonitor: any NowPlayingAudioLevelMonitoring
    private let artworkFlipAnimationDuration: TimeInterval = 0.45
    private let artworkSwapDelay: TimeInterval = 0.4
    private let transientSessionGracePeriod: TimeInterval = 0.55
    private var hasStartedMonitoring = false
    private var ignoresServiceSnapshots = false
    private var artworkFlipCooldownActive = false
    private var artworkPresentationWorkItem: DispatchWorkItem?
    private var pendingSessionEndWorkItem: DispatchWorkItem?
    private var artworkFlipTrackKey: String?
    private var artworkFlipStartedAt: Date?
    private var activeAudioReactiveVisualizationSources = Set<String>()
    private var cancellables = Set<AnyCancellable>()
    #if DEBUG
    private var isShowingDebugPreviewSnapshot = false
    #endif

    var hasActiveSession: Bool {
        snapshot != nil
    }

    private static let emptyReactiveLevels = Array(repeating: CGFloat(0), count: 5)

    convenience init() {
        self.init(
            service: MediaRemoteNowPlayingService(),
            audioOutputRouting: SystemAudioOutputRoutingService(),
            favoritesStore: .standard,
            mediaSettings: MediaAndFilesSettingsStore(defaults: .standard),
            audioLevelMonitor: SystemNowPlayingAudioLevelMonitor()
        )
    }

    init(
        service: any NowPlayingMonitoring,
        audioOutputRouting: (any AudioOutputRouting)? = nil,
        favoritesStore: UserDefaults = .standard,
        mediaSettings: MediaAndFilesSettingsStore? = nil,
        audioLevelMonitor: (any NowPlayingAudioLevelMonitoring)? = nil
    ) {
        self.service = service
        self.audioOutputRouting = audioOutputRouting ?? InactiveAudioOutputRoutingService()
        self.favoritesStore = favoritesStore
        self.mediaSettings = mediaSettings ?? MediaAndFilesSettingsStore(defaults: favoritesStore)
        self.audioLevelMonitor = audioLevelMonitor ?? SystemNowPlayingAudioLevelMonitor()
        self.service.onSnapshotChange = { [weak self] snapshot in
            guard let self else { return }

            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self.handleServiceSnapshot(snapshot)
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.handleServiceSnapshot(snapshot)
                }
            }
        }
        self.audioLevelMonitor.onLevelsChange = { [weak self] levels in
            guard let self else { return }

            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self.audioReactiveLevels = levels
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.audioReactiveLevels = levels
                }
            }
        }
        bindAudioReactiveMonitoring()
        refreshAudioOutputRoutes()
    }

    deinit {
        let monitor = audioLevelMonitor
        Task { @MainActor in
            monitor.stopMonitoring()
        }
    }

    func startMonitoring() {
        guard !hasStartedMonitoring else { return }
        hasStartedMonitoring = true
        ignoresServiceSnapshots = false
        service.startMonitoring()
        updateAudioReactiveMonitoringState()
    }

    func stopMonitoring() {
        guard hasStartedMonitoring else { return }
        hasStartedMonitoring = false
        ignoresServiceSnapshots = true
        service.stopMonitoring()
        cancelPendingSessionEnd()
        cancelPendingArtworkPresentation()
        apply(snapshot: nil)
    }

    func togglePlayPause() {
        if let snapshot {
            apply(snapshot: snapshot.togglingPlaybackState())
        }

        service.send(.togglePlayPause)
    }

    func nextTrack() {
        service.send(.nextTrack)
    }

    func previousTrack() {
        service.send(.previousTrack)
    }

    func seek(to elapsedTime: TimeInterval) {
        guard let snapshot, snapshot.duration > 0 else { return }

        let clampedElapsedTime = min(max(elapsedTime, 0), snapshot.duration)
        apply(snapshot: snapshot.settingElapsedTime(clampedElapsedTime))
        service.send(.seek(clampedElapsedTime))
    }

    func refreshAudioOutputRoutes() {
        let routes = audioOutputRouting.availableRoutes()
        audioOutputRoutes = routes
        currentAudioOutputRoute = routes.first(where: \.isCurrent)
    }

    func switchAudioOutput(to route: AudioOutputRoute) {
        guard audioOutputRouting.setCurrentRoute(route.id) else {
            refreshAudioOutputRoutes()
            return
        }

        refreshAudioOutputRoutes()
    }

    var canToggleFavorite: Bool {
        snapshot?.favoriteTrackKey != nil
    }

    func toggleFavorite() {
        guard let favoriteTrackKey = snapshot?.favoriteTrackKey else { return }

        var favoriteTrackKeys = storedFavoriteTrackKeys

        if favoriteTrackKeys.contains(favoriteTrackKey) {
            favoriteTrackKeys.remove(favoriteTrackKey)
        } else {
            favoriteTrackKeys.insert(favoriteTrackKey)
        }

        favoritesStore.set(Array(favoriteTrackKeys).sorted(), forKey: Self.favoriteTrackKeysStorageKey)
        isCurrentTrackFavorite = favoriteTrackKeys.contains(favoriteTrackKey)
    }

    func elapsedTime(at date: Date) -> TimeInterval {
        snapshot?.elapsedTime(at: date) ?? 0
    }

    func setAudioReactiveVisualizationActive(_ isActive: Bool, source: String) {
        if isActive {
            activeAudioReactiveVisualizationSources.insert(source)
        } else {
            activeAudioReactiveVisualizationSources.remove(source)
        }

        updateAudioReactiveMonitoringState()
    }

    #if DEBUG
    func showDebugPreviewSnapshotIfNeeded() {
        guard snapshot == nil else { return }
        isShowingDebugPreviewSnapshot = true
        apply(snapshot: Self.makeDebugPreviewSnapshot(), emitEvent: false)
    }

    func hideDebugPreviewSnapshotIfNeeded() {
        guard isShowingDebugPreviewSnapshot else { return }
        isShowingDebugPreviewSnapshot = false
        apply(snapshot: nil, emitEvent: false)
    }

    private static func makeDebugPreviewSnapshot() -> NowPlayingSnapshot {
        NowPlayingSnapshot(
            title: "Midnight Echoes",
            artist: "Debug Ensemble",
            album: "Preview Mode",
            duration: 214,
            elapsedTime: 81,
            playbackRate: 1,
            artworkData: makeDebugArtworkData(),
            refreshedAt: .now
        )
    }

    private static func makeDebugArtworkData() -> Data? {
        let size = NSSize(width: 48, height: 48)
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )

        guard let rep else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

        let bounds = NSRect(origin: .zero, size: size)
        NSColor(calibratedRed: 0.96, green: 0.48, blue: 0.2, alpha: 1).setFill()
        NSBezierPath(rect: bounds).fill()

        NSColor(calibratedRed: 1, green: 0.79, blue: 0.29, alpha: 1).setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: size.width * 0.42, height: size.height)).fill()

        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .png, properties: [:])
    }
    #endif
}

private extension NowPlayingViewModel {
    func handleServiceSnapshot(_ snapshot: NowPlayingSnapshot?) {
        guard !ignoresServiceSnapshots else { return }

        if let snapshot {
            cancelPendingSessionEnd()
            apply(snapshot: snapshot)
        } else {
            scheduleSessionEnd()
        }
    }

    func bindAudioReactiveMonitoring() {
        mediaSettings.$nowPlayingEqualizerMode
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateAudioReactiveMonitoringState()
            }
            .store(in: &cancellables)
    }

    var storedFavoriteTrackKeys: Set<String> {
        Set(favoritesStore.stringArray(forKey: Self.favoriteTrackKeysStorageKey) ?? [])
    }

    func apply(snapshot newSnapshot: NowPlayingSnapshot?, emitEvent: Bool = true) {
        let wasActive = snapshot != nil
        let previousTrackKey = snapshot?.favoriteTrackKey
        let newTrackKey = newSnapshot?.favoriteTrackKey
        let previousArtworkData = snapshot?.artworkData
        let didTrackChange = previousTrackKey != nil &&
            newTrackKey != nil &&
            previousTrackKey != newTrackKey

        if previousTrackKey != newTrackKey {
            cancelPendingArtworkPresentation()
        }

        if didTrackChange {
            triggerArtworkFlip(for: newTrackKey)
        }

        snapshot = newSnapshot
        isCurrentTrackFavorite = newSnapshot?.favoriteTrackKey.map(storedFavoriteTrackKeys.contains) ?? false

        switch newSnapshot?.artworkData {
        case let artworkData?:
            guard previousArtworkData != artworkData || artworkImage == nil else {
                break
            }

            if shouldDelayArtworkPresentation(for: newTrackKey) {
                scheduleArtworkPresentation(artworkData, for: newTrackKey)
            } else {
                applyArtworkPresentation(artworkData)
            }
        case nil:
            if newSnapshot == nil || previousArtworkData == nil {
                cancelPendingArtworkPresentation()
                artworkImage = nil
                artworkPalette = .fallback
            }
        }

        let isActive = newSnapshot != nil

        if emitEvent {
            if !wasActive && isActive {
                event = .started
            } else if wasActive && !isActive {
                event = .stopped
            }
        }

        updateAudioReactiveMonitoringState()
    }

    func updateAudioReactiveMonitoringState() {
        let shouldUseAudioReactiveMonitoring =
            hasStartedMonitoring &&
            !activeAudioReactiveVisualizationSources.isEmpty &&
            mediaSettings.nowPlayingEqualizerMode == .audioReactive &&
            snapshot?.isPlaying == true

        if shouldUseAudioReactiveMonitoring {
            audioLevelMonitor.startMonitoring()
        } else {
            audioLevelMonitor.stopMonitoring()

            if audioReactiveLevels != Self.emptyReactiveLevels {
                audioReactiveLevels = Self.emptyReactiveLevels
            }
        }
    }

    func scheduleSessionEnd() {
        guard snapshot != nil else { return }
        guard pendingSessionEndWorkItem == nil else { return }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingSessionEndWorkItem = nil
            self.cancelPendingArtworkPresentation()
            self.apply(snapshot: nil)
        }

        pendingSessionEndWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + transientSessionGracePeriod, execute: workItem)
    }

    func cancelPendingSessionEnd() {
        pendingSessionEndWorkItem?.cancel()
        pendingSessionEndWorkItem = nil
    }

    func triggerArtworkFlip(for trackKey: String?) {
        guard !artworkFlipCooldownActive else { return }

        artworkFlipCooldownActive = true
        artworkFlipTrackKey = trackKey
        artworkFlipStartedAt = .now

        withAnimation(.easeInOut(duration: artworkFlipAnimationDuration)) {
            artworkFlipAngle += 180
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + artworkFlipAnimationDuration + 0.15) { [weak self] in
            guard let self else { return }

            if self.artworkFlipTrackKey == trackKey {
                self.artworkFlipTrackKey = nil
                self.artworkFlipStartedAt = nil
            }

            self.artworkFlipCooldownActive = false
        }
    }

    func shouldDelayArtworkPresentation(for trackKey: String?) -> Bool {
        guard let trackKey else { return false }
        return artworkFlipTrackKey == trackKey && artworkFlipStartedAt != nil
    }

    func scheduleArtworkPresentation(_ artworkData: Data, for trackKey: String?) {
        cancelPendingArtworkPresentation()

        let elapsed = artworkFlipStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        let delay = max(0, artworkSwapDelay - elapsed)
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.snapshot?.favoriteTrackKey == trackKey else { return }
            self.applyArtworkPresentation(artworkData)
        }

        artworkPresentationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    func cancelPendingArtworkPresentation() {
        artworkPresentationWorkItem?.cancel()
        artworkPresentationWorkItem = nil
    }

    func applyArtworkPresentation(_ artworkData: Data) {
        cancelPendingArtworkPresentation()
        artworkImage = NSImage(data: artworkData)
        artworkPalette = NowPlayingArtworkPaletteExtractor.extract(from: artworkData)
    }
}

final class InactiveNowPlayingAudioLevelMonitor: NowPlayingAudioLevelMonitoring {
    var onLevelsChange: (([CGFloat]) -> Void)?

    func startMonitoring() {}
    func stopMonitoring() {
        onLevelsChange?(Array(repeating: 0, count: 5))
    }
}

#if canImport(ScreenCaptureKit)
final class SystemNowPlayingAudioLevelMonitor: NSObject, NowPlayingAudioLevelMonitoring {
    struct NormalizedAudioFrame {
        let samples: [Float]
        let sampleRate: Double
    }

    var onLevelsChange: (([CGFloat]) -> Void)?

    private let sampleHandlerQueue = DispatchQueue(
        label: "com.dynamicnotch.nowplaying.audioReactive",
        qos: .userInitiated
    )
    private let fftSize = 2048
    private let bandFrequencyRanges: [ClosedRange<Float>] = [
        20...125,
        125...315,
        315...1_250,
        1_250...4_200,
        4_200...12_000
    ]
    private let bandGains: [Float] = [2.45, 2.05, 1.72, 1.46, 1.7]

    private var stream: SCStream?
    private var startTask: Task<Void, Never>?
    private var isMonitoring = false
    private var hasPromptedForScreenCaptureAccess = false
    private var sampleHistory: [Float] = []
    private var smoothedBandLevels = Array(repeating: CGFloat(0), count: 5)
    private var adaptiveBandPeaks: [Float] = [0.08, 0.065, 0.055, 0.045, 0.04]
    private var adaptiveBandFloors: [Float] = [0.004, 0.0035, 0.003, 0.0026, 0.0022]
    private var previousBassCarrier: Float = 0
    private var bassImpactLevel: Float = 0
    private lazy var discreteFourierTransform = try? vDSP.DiscreteFourierTransform(
        count: fftSize,
        direction: .forward,
        transformType: .complexComplex,
        ofType: Float.self
    )
    private lazy var fftWindow = vDSP.window(
        ofType: Float.self,
        usingSequence: .hanningDenormalized,
        count: fftSize,
        isHalfWindow: false
    )

    private lazy var zeroImaginarySamples = Array(repeating: Float(0), count: fftSize)

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        guard !isMonitoring, startTask == nil else { return }

        guard hasScreenCaptureAccess() else {
            requestScreenCaptureAccessIfNeeded()
            onLevelsChange?(Array(repeating: 0, count: bandFrequencyRanges.count))
            return
        }

        startTask = Task { [weak self] in
            await self?.startStream()
        }
    }

    func stopMonitoring() {
        startTask?.cancel()
        startTask = nil

        let activeStream = stream
        stream = nil
        isMonitoring = false
        sampleHistory.removeAll(keepingCapacity: false)
        smoothedBandLevels = Array(repeating: 0, count: bandFrequencyRanges.count)
        adaptiveBandPeaks = [0.08, 0.065, 0.055, 0.045, 0.04]
        adaptiveBandFloors = [0.004, 0.0035, 0.003, 0.0026, 0.0022]
        previousBassCarrier = 0
        bassImpactLevel = 0
        onLevelsChange?(Array(repeating: 0, count: bandFrequencyRanges.count))

        guard let activeStream else { return }

        Task {
            try? await activeStream.stopCapture()
        }
    }
}

private extension SystemNowPlayingAudioLevelMonitor {
    func startStream() async {
        defer { startTask = nil }

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )

            guard let display = content.displays.first else {
                onLevelsChange?(Array(repeating: 0, count: bandFrequencyRanges.count))
                return
            }

            let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
            let configuration = SCStreamConfiguration()
            configuration.queueDepth = 1
            configuration.width = 2
            configuration.height = 2
            configuration.capturesAudio = true
            configuration.excludesCurrentProcessAudio = true
            configuration.sampleRate = 48_000
            configuration.channelCount = 2

            let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
            try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: sampleHandlerQueue)
            try await stream.startCapture()

            guard !Task.isCancelled else {
                try? await stream.stopCapture()
                return
            }

            self.stream = stream
            self.isMonitoring = true
        } catch {
            onLevelsChange?(Array(repeating: 0, count: bandFrequencyRanges.count))
            isMonitoring = false
        }
    }

    func handleAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let frame = normalizedAudioFrame(from: sampleBuffer) else { return }

        append(samples: frame.samples)
        let resolvedLevels = spectralBandLevels(from: sampleHistory, sampleRate: frame.sampleRate)
        smooth(levels: resolvedLevels)

        DispatchQueue.main.async { [weak self] in
            self?.onLevelsChange?(self?.smoothedBandLevels ?? Array(repeating: 0, count: 5))
        }
    }

    func normalizedAudioFrame(from sampleBuffer: CMSampleBuffer) -> NormalizedAudioFrame? {
        guard
            CMSampleBufferIsValid(sampleBuffer),
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
            let asbdPointer = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
        else {
            return nil
        }

        let asbd = asbdPointer.pointee
        let channelCount = max(Int(asbd.mChannelsPerFrame), 1)
        let bitsPerChannel = max(Int(asbd.mBitsPerChannel), 1)
        let bytesPerSample = max(bitsPerChannel / 8, 1)
        let isNonInterleaved = (asbd.mFormatFlags & kAudioFormatFlagIsNonInterleaved) != 0
        let bufferListSize = MemoryLayout<AudioBufferList>.size +
            (channelCount - 1) * MemoryLayout<AudioBuffer>.size

        let audioBufferListPointer = UnsafeMutableRawPointer.allocate(
            byteCount: bufferListSize,
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer { audioBufferListPointer.deallocate() }

        let audioBufferList = audioBufferListPointer.bindMemory(to: AudioBufferList.self, capacity: 1)
        var blockBuffer: CMBlockBuffer?

        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: audioBufferList,
            bufferListSize: bufferListSize,
            blockBufferAllocator: kCFAllocatorDefault,
            blockBufferMemoryAllocator: kCFAllocatorDefault,
            flags: UInt32(kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment),
            blockBufferOut: &blockBuffer
        )

        guard status == noErr else { return nil }

        let isFloat = (asbd.mFormatFlags & kAudioFormatFlagIsFloat) != 0
        let isSignedInteger = (asbd.mFormatFlags & kAudioFormatFlagIsSignedInteger) != 0
        let audioBuffers = UnsafeMutableAudioBufferListPointer(audioBufferList)

        guard let firstBuffer = audioBuffers.first, firstBuffer.mData != nil else { return nil }

        let normalizedSamples: [Float]

        if isFloat {
            if isNonInterleaved {
                normalizedSamples = normalizedFloatSamples(
                    from: audioBuffers,
                    channelCount: channelCount,
                    bytesPerSample: bytesPerSample
                )
            } else {
                normalizedSamples = normalizedInterleavedFloatSamples(
                    from: firstBuffer,
                    channelCount: channelCount,
                    bytesPerSample: bytesPerSample
                )
            }
        } else if isSignedInteger && bitsPerChannel == 16 {
            if isNonInterleaved {
                normalizedSamples = normalizedInt16Samples(
                    from: audioBuffers,
                    channelCount: channelCount,
                    bytesPerSample: bytesPerSample
                )
            } else {
                normalizedSamples = normalizedInterleavedInt16Samples(
                    from: firstBuffer,
                    channelCount: channelCount,
                    bytesPerSample: bytesPerSample
                )
            }
        } else {
            return nil
        }

        guard !normalizedSamples.isEmpty else { return nil }
        return NormalizedAudioFrame(samples: normalizedSamples, sampleRate: asbd.mSampleRate)
    }

    func normalizedInterleavedFloatSamples(
        from audioBuffer: AudioBuffer,
        channelCount: Int,
        bytesPerSample: Int
    ) -> [Float] {
        guard let mData = audioBuffer.mData else { return [] }

        let frameCount = Int(audioBuffer.mDataByteSize) / (bytesPerSample * channelCount)
        guard frameCount > 0 else { return [] }

        let samples = mData.assumingMemoryBound(to: Float.self)
        var mono = Array(repeating: Float(0), count: frameCount)

        for frameIndex in 0..<frameCount {
            let baseIndex = frameIndex * channelCount
            var sum: Float = 0

            for channelIndex in 0..<channelCount {
                sum += samples[baseIndex + channelIndex]
            }

            mono[frameIndex] = sum / Float(channelCount)
        }

        return mono
    }

    func normalizedFloatSamples(
        from audioBuffers: UnsafeMutableAudioBufferListPointer,
        channelCount: Int,
        bytesPerSample: Int
    ) -> [Float] {
        guard let firstBuffer = audioBuffers.first, firstBuffer.mData != nil else {
            return []
        }

        let frameCount = Int(firstBuffer.mDataByteSize) / bytesPerSample
        guard frameCount > 0 else { return [] }

        var mono = Array(repeating: Float(0), count: frameCount)
        let resolvedBufferCount = min(audioBuffers.count, channelCount)

        for bufferIndex in 0..<resolvedBufferCount {
            guard let bufferData = audioBuffers[bufferIndex].mData else { continue }
            let samples = bufferData.assumingMemoryBound(to: Float.self)

            for frameIndex in 0..<frameCount {
                mono[frameIndex] += samples[frameIndex]
            }
        }

        let divider = Float(max(resolvedBufferCount, 1))
        for frameIndex in 0..<frameCount {
            mono[frameIndex] /= divider
        }
        return mono
    }

    func normalizedInterleavedInt16Samples(
        from audioBuffer: AudioBuffer,
        channelCount: Int,
        bytesPerSample: Int
    ) -> [Float] {
        guard let mData = audioBuffer.mData else { return [] }

        let frameCount = Int(audioBuffer.mDataByteSize) / (bytesPerSample * channelCount)
        guard frameCount > 0 else { return [] }

        let samples = mData.assumingMemoryBound(to: Int16.self)
        let normalizer = Float(Int16.max)
        var mono = Array(repeating: Float(0), count: frameCount)

        for frameIndex in 0..<frameCount {
            let baseIndex = frameIndex * channelCount
            var sum: Float = 0

            for channelIndex in 0..<channelCount {
                sum += Float(samples[baseIndex + channelIndex]) / normalizer
            }

            mono[frameIndex] = sum / Float(channelCount)
        }

        return mono
    }

    func normalizedInt16Samples(
        from audioBuffers: UnsafeMutableAudioBufferListPointer,
        channelCount: Int,
        bytesPerSample: Int
    ) -> [Float] {
        guard let firstBuffer = audioBuffers.first else { return [] }

        let frameCount = Int(firstBuffer.mDataByteSize) / bytesPerSample
        guard frameCount > 0 else { return [] }

        var mono = Array(repeating: Float(0), count: frameCount)
        let resolvedBufferCount = min(audioBuffers.count, channelCount)
        let normalizer = Float(Int16.max)

        for bufferIndex in 0..<resolvedBufferCount {
            guard let bufferData = audioBuffers[bufferIndex].mData else { continue }
            let samples = bufferData.assumingMemoryBound(to: Int16.self)

            for frameIndex in 0..<frameCount {
                mono[frameIndex] += Float(samples[frameIndex]) / normalizer
            }
        }

        let divider = Float(max(resolvedBufferCount, 1))
        for frameIndex in 0..<frameCount {
            mono[frameIndex] /= divider
        }

        return mono
    }

    func append(samples: [Float]) {
        sampleHistory.append(contentsOf: samples)

        if sampleHistory.count > fftSize {
            sampleHistory.removeFirst(sampleHistory.count - fftSize)
        }
    }

    func spectralBandLevels(from samples: [Float], sampleRate: Double) -> [CGFloat] {
        guard
            samples.count >= 128,
            let discreteFourierTransform
        else {
            return Array(repeating: 0, count: bandFrequencyRanges.count)
        }

        var paddedSamples = Array(repeating: Float(0), count: fftSize)
        let copyCount = min(samples.count, fftSize)
        let startIndex = samples.count - copyCount

        for offset in 0..<copyCount {
            paddedSamples[offset] = samples[startIndex + offset]
        }

        var windowedSamples = Array(repeating: Float(0), count: fftSize)
        vDSP_vmul(paddedSamples, 1, fftWindow, 1, &windowedSamples, 1, vDSP_Length(fftSize))

        var real = Array(repeating: Float(0), count: fftSize)
        var imaginary = Array(repeating: Float(0), count: fftSize)
        discreteFourierTransform.transform(
            inputReal: windowedSamples,
            inputImaginary: zeroImaginarySamples,
            outputReal: &real,
            outputImaginary: &imaginary
        )

        let positiveSpectrumCount = fftSize / 2
        var magnitudes = Array(repeating: Float(0), count: positiveSpectrumCount)
        for index in 0..<positiveSpectrumCount {
            let realPart = real[index]
            let imaginaryPart = imaginary[index]
            magnitudes[index] = sqrt((realPart * realPart) + (imaginaryPart * imaginaryPart))
        }

        let binWidth = Float(sampleRate) / Float(fftSize)
        let spectralFloor = max(rms(of: samples), 0.004)
        let rawBands = bandFrequencyRanges.enumerated().map { index, range -> Float in
            let lowerBin = max(Int(floor(range.lowerBound / binWidth)), 1)
            let upperBin = min(Int(ceil(range.upperBound / binWidth)), magnitudes.count - 1)

            guard lowerBin <= upperBin else { return 0 }

            var sum: Float = 0
            for bin in lowerBin...upperBin {
                sum += magnitudes[bin]
            }

            let averageMagnitude = sum / Float(upperBin - lowerBin + 1)
            return averageMagnitude * bandGains[index]
        }

        let ensembleReference = max(rawBands.reduce(0, +) / Float(rawBands.count), spectralFloor * 3.2)
        let loudness = min(max(pow(spectralFloor * 2.8, 0.6), 0), 1)
        let relativeBiases: [Float] = [1.55, 1.18, 0.96, 0.82, 0.7]
        let responseCurves: [Float] = [0.68, 0.74, 0.8, 0.84, 0.88]
        let peakReleases: [Float] = [0.82, 0.86, 0.88, 0.9, 0.92]
        var isolatedBands = Array(repeating: Float(0), count: rawBands.count)
        var minimumPeaks = Array(repeating: Float(0), count: rawBands.count)

        for (index, rawBand) in rawBands.enumerated() {
            let targetFloor = max(rawBand * 0.035, spectralFloor * (0.55 - (Float(index) * 0.06)))
            let currentFloor = adaptiveBandFloors[index]
            let floorBlend: Float = rawBand < currentFloor ? 0.16 : 0.035
            let updatedFloor = (currentFloor * (1 - floorBlend)) + (targetFloor * floorBlend)
            adaptiveBandFloors[index] = max(updatedFloor, spectralFloor * 0.18)

            let isolatedBand = max(rawBand - adaptiveBandFloors[index], 0)
            let minimumPeak = max((ensembleReference * 0.18) / relativeBiases[index], spectralFloor * 0.85)
            let currentPeak = adaptiveBandPeaks[index]

            if isolatedBand > currentPeak {
                adaptiveBandPeaks[index] += (isolatedBand - currentPeak) * 0.34
            } else {
                adaptiveBandPeaks[index] = max(minimumPeak, currentPeak * peakReleases[index])
            }
            isolatedBands[index] = isolatedBand
            minimumPeaks[index] = minimumPeak
        }

        var resolvedLevels = rawBands.enumerated().map { index, _ in
            let isolatedBand = isolatedBands[index]
            let peakNormalized = isolatedBand / max(adaptiveBandPeaks[index], minimumPeaks[index])
            let ensembleNormalized = isolatedBand / max(ensembleReference * relativeBiases[index], spectralFloor * 1.6)
            let combined = min(max((peakNormalized * 0.72) + (ensembleNormalized * 0.28), 0), 1.35)
            let shaped = pow(combined, responseCurves[index])
            let gated = max(shaped - 0.025, 0) / 0.975
            let resolvedLevel = gated * (0.14 + (loudness * 0.86))
            return Float(min(max(resolvedLevel, 0), 1))
        }

        if !resolvedLevels.isEmpty {
            let lowMidContribution = isolatedBands.indices.contains(1) ? isolatedBands[1] * 0.22 : 0
            let bassCarrier = (isolatedBands[0] * 0.78) + lowMidContribution
            let previousCarrier = previousBassCarrier
            previousBassCarrier = (previousBassCarrier * 0.56) + (bassCarrier * 0.44)

            let bassRise = max(bassCarrier - previousCarrier, 0)
            let bassReference = max(adaptiveBandPeaks[0] * 0.32, ensembleReference * 0.18, spectralFloor * 1.2)
            let targetImpact = min(max(bassRise / bassReference, 0), 1.15)

            if targetImpact > bassImpactLevel {
                bassImpactLevel += (targetImpact - bassImpactLevel) * 0.52
            } else {
                bassImpactLevel = (bassImpactLevel * 0.72) + (targetImpact * 0.28)
            }

            let bassTransient = pow(min(max(bassImpactLevel, 0), 1), 0.84)
            let bassSustain = resolvedLevels[0] * 0.34
            resolvedLevels[0] = min(max((bassTransient * 0.72) + bassSustain, 0), 1)
        }

        return resolvedLevels.map(CGFloat.init)
    }

    func smooth(levels: [CGFloat]) {
        for index in smoothedBandLevels.indices {
            let incoming = index < levels.count ? levels[index] : 0
            let current = smoothedBandLevels[index]
            let attacks: [CGFloat] = [0.58, 0.56, 0.52, 0.48, 0.46]
            let releases: [CGFloat] = [0.68, 0.74, 0.78, 0.82, 0.86]

            if incoming > current {
                smoothedBandLevels[index] += (incoming - current) * attacks[index]
            } else {
                smoothedBandLevels[index] = max(incoming, current * releases[index])
            }
        }
    }

    func rms(of samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }

        var sumSquares: Float = 0
        for sample in samples {
            sumSquares += sample * sample
        }

        return sqrt(sumSquares / Float(samples.count))
    }

    func hasScreenCaptureAccess() -> Bool {
        #if canImport(ApplicationServices)
        return CGPreflightScreenCaptureAccess()
        #else
        return true
        #endif
    }

    func requestScreenCaptureAccessIfNeeded() {
        guard !hasPromptedForScreenCaptureAccess else { return }
        hasPromptedForScreenCaptureAccess = true

        #if canImport(ApplicationServices)
        _ = CGRequestScreenCaptureAccess()
        #endif
    }
}

extension SystemNowPlayingAudioLevelMonitor: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .audio else { return }
        handleAudioSampleBuffer(sampleBuffer)
    }
}
#else
typealias SystemNowPlayingAudioLevelMonitor = InactiveNowPlayingAudioLevelMonitor
#endif

private extension NowPlayingSnapshot {
    var favoriteTrackKey: String? {
        let components = [title.trimmed, artist.trimmed, album.trimmed]
        let joined = components.joined(separator: "|")
        return joined.replacingOccurrences(of: "|", with: "").isEmpty ? nil : joined
    }

    func togglingPlaybackState() -> Self {
        Self(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: elapsedTime(at: .now),
            playbackRate: isPlaying ? 0 : 1,
            artworkData: artworkData,
            refreshedAt: .now
        )
    }

    func settingElapsedTime(_ newElapsedTime: TimeInterval) -> Self {
        Self(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: min(max(newElapsedTime, 0), duration > 0 ? duration : newElapsedTime),
            playbackRate: playbackRate,
            artworkData: artworkData,
            refreshedAt: .now
        )
    }
}
