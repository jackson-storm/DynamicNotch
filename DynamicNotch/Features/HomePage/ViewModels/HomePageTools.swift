import Combine

@MainActor
final class HomePageTools: ObservableObject {
    let screenshots = ScreenshotCaptureModel()
    let calculator = MiniCalculatorModel()
    let sound: SoundControlModel

    init(audioService: SystemAudioVolumeService) {
        sound = SoundControlModel(audioService: audioService)
    }
}
