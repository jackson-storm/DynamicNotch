//
//  NotchContentRegistry.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import Foundation

enum NotchContentRegistry {
    enum HUD {
        static let system = NotchContentDescriptor(id: "hud.system")
        static let keyboard = NotchContentDescriptor(id: "hud.keyboard")
    }
    
    enum Power {
        static let charger = NotchContentDescriptor(id: "battery.charger")
        static let lowPower = NotchContentDescriptor(id: "battery.lowPower")
        static let fullPower = NotchContentDescriptor(id: "battery.fullPower")
    }

    enum Focus {
        static let active = NotchContentDescriptor(
            id: "focus.on",
            priorityKey: .focus
        )
        static let inactive = NotchContentDescriptor(id: "focus.off")
    }

    enum ScreenRecording {
        static let active = NotchContentDescriptor(
            id: "screen.recording",
            priorityKey: .screenRecording
        )
        static let inactive = NotchContentDescriptor(id: "screen.recording.inactive")
    }

    enum Network {
        static let bluetooth = NotchContentDescriptor(id: "bluetooth.connected")
        static let hotspot = NotchContentDescriptor(
            id: "hotspot.active",
            priorityKey: .hotspot
        )
        static let wifi = NotchContentDescriptor(id: "wifi.connected")
        static let vpn = NotchContentDescriptor(id: "vpn.connected")
        static let noInternet = NotchContentDescriptor(id: "network.noInternetConnection")
    }

    enum Media {
        static let nowPlaying = NotchContentDescriptor(
            id: "nowPlaying",
            priorityKey: .nowPlaying
        )
        static let download = NotchContentDescriptor(
            id: "download.active",
            priorityKey: .download
        )
        static let timer = NotchContentDescriptor(
            id: "clock.timer",
            priorityKey: .timer
        )
        static let localTimer = NotchContentDescriptor(
            id: "clock.localTimer",
            priorityKey: .timer
        )
    }
    
    enum HomePage {
        static let active = NotchContentDescriptor(
            id: "home.active",
            priorityKey: .homePage
        )
    }

    enum DragAndDrop {
        static let airDrop = NotchContentDescriptor(
            id: "airdrop",
            priority: NotchContentPriority.dragAndDrop
        )
        static let tray = NotchContentDescriptor(
            id: "tray",
            priority: NotchContentPriority.dragAndDrop
        )
        static let fileConverter = NotchContentDescriptor(
            id: "fileConverter",
            priority: NotchContentPriority.dragAndDrop
        )
        static let combined = NotchContentDescriptor(
            id: "dragAndDrop.combined",
            priority: NotchContentPriority.dragAndDrop
        )
        
        static let trayActive = NotchContentDescriptor(
            id: "tray.active",
            priorityKey: .trayActive
        )
        static let fileConverterActive = NotchContentDescriptor(
            id: "fileConverter.active",
            priorityKey: .fileConverterActive
        )
        static let fileConverterConverted = NotchContentDescriptor(
            id: "fileConverter.converted"
        )

        static let liveActivityIDs = [
            airDrop.id,
            tray.id,
            fileConverter.id,
            combined.id
        ]
    }

    enum LockScreen {
        static let activity = NotchContentDescriptor(
            id: "lockScreen",
            priority: NotchContentPriority.lockScreen
        )
    }

    enum NotchSize {
        static let width = NotchContentDescriptor(
            id: "notchSize.width",
            priority: NotchContentPriority.notchSizeWidth
        )
        static let height = NotchContentDescriptor(
            id: "notchSize.height",
            priority: NotchContentPriority.notchSizeHeight
        )
    }

    enum Onboarding {
        static let stackID = "onboarding"
        static let debugStackID = "onboarding.debug"
        static let priority = NotchContentPriority.onboarding

        static func id(forStep rawValue: String) -> String {
            "\(stackID).\(rawValue)"
        }

        #if DEBUG
        static func debugID(forStep rawValue: String) -> String {
            "\(debugStackID).\(rawValue)"
        }
        #endif
    }

    enum DebugSequence {
        static let prefix = "debug.sequence."

        static let onboarding = id(Onboarding.debugStackID)
        static let focus = id(Focus.active.id)
        static let focusOff = id(Focus.inactive.id)
        static let screenRecording = id(ScreenRecording.active.id)
        static let screenRecordingInactive = id(ScreenRecording.inactive.id)
        static let hotspot = id(Network.hotspot.id)
        static let nowPlaying = id(Media.nowPlaying.id)
        static let download = id(Media.download.id)
        static let timer = id(Media.timer.id)
        static let airDrop = id(DragAndDrop.airDrop.id)
        static let tray = id(DragAndDrop.tray.id)
        static let fileConverter = id(DragAndDrop.fileConverter.id)
        static let combinedDrop = id(DragAndDrop.combined.id)
        static let trayActive = id(DragAndDrop.trayActive.id)
        static let fileConverterActive = id(DragAndDrop.fileConverterActive.id)
        static let fileConverterConverted = id(DragAndDrop.fileConverterConverted.id)
        static let bluetooth = id(Network.bluetooth.id)
        static let wifi = id(Network.wifi.id)
        static let vpn = id(Network.vpn.id)
        static let noInternet = id(Network.noInternet.id)
        static let charging = id("charger")
        static let lowPower = id("lowPower")
        static let fullPower = id("fullPower")
        static let hudBrightness = id("hud.brightness")
        static let hudKeyboard = id("hud.keyboard")
        static let hudVolume = id("hud.volume")
        static let notchSizeWidth = id(NotchSize.width.id)
        static let notchSizeHeight = id(NotchSize.height.id)
        static let lockScreen = id(LockScreen.activity.id)

        static func id(_ suffix: String) -> String {
            "\(prefix)\(suffix)"
        }
    }
}
