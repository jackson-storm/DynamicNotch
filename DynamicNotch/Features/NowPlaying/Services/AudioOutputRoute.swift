import CoreAudio
import Foundation

struct AudioOutputRoute: Identifiable, Equatable {
    let id: AudioDeviceID
    let name: String
    let transportType: UInt32
    let isCurrent: Bool

    var systemImageName: String {
        let lowercaseName = name.lowercased()

        switch transportType {
        case kAudioDeviceTransportTypeAirPlay:
            return "airplayaudio"

        case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE:
            if lowercaseName.contains("airpods max") {
                return "airpodsmax"
            }

            if lowercaseName.contains("airpods pro") {
                return "airpods.pro"
            }

            if lowercaseName.contains("airpods 4") || lowercaseName.contains("airpods4") {
                return "airpods.gen4"
            }

            if lowercaseName.contains("airpods 3") || lowercaseName.contains("airpods3") {
                return "airpods.gen3"
            }

            if lowercaseName.contains("airpods") {
                return "airpods"
            }

            if lowercaseName.contains("speaker") {
                return "hifispeaker.fill"
            }

            return "headphones"

        case kAudioDeviceTransportTypeBuiltIn:
            if lowercaseName.contains("speaker") {
                return "hifispeaker.fill"
            }

            if lowercaseName.contains("macbook") {
                return "macbook"
            }

            return "speaker.wave.2.fill"

        case kAudioDeviceTransportTypeHDMI, kAudioDeviceTransportTypeDisplayPort:
            return "tv"

        case kAudioDeviceTransportTypeUSB, kAudioDeviceTransportTypeThunderbolt:
            return lowercaseName.contains("headphone") ? "headphones" : "hifispeaker.fill"

        default:
            return "speaker.wave.2.fill"
        }
    }
}
