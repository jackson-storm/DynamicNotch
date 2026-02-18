//
//  DeviceType.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/17/26.
//

enum BluetoothDeviceType {
    case headset
    case headphones
    case speaker
    case mouse
    case keyboard
    case combo
    case computer
    case phone
    case unknown
}

extension BluetoothDeviceType {
    var symbolName: String {
        switch self {
        case .headset: return "headphones"
        case .headphones: return "airpods"
        case .speaker: return "speaker.wave.2.fill"
        case .mouse: return "magicmouse.fill"
        case .keyboard: return "keyboard.fill"
        case .combo: return "keyboard.fill"
        case .computer: return "desktopcomputer"
        case .phone: return "iphone"
        case .unknown: return "questionmark"
        }
    }
}
