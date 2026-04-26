import Foundation

struct NotchContentDescriptor: Equatable {
    let id: String
    let stackID: String
    let priority: Int

    init(
        id: String,
        stackID: String? = nil,
        priority: Int = NotchContentPriority.default
    ) {
        self.id = id
        self.stackID = stackID ?? id
        self.priority = priority
    }
}

enum NotchContentPriority {
    static let `default` = 0
    static let focus = 1
    static let notchSizeWidth = 2
    static let notchSizeHeight = 3
    static let hotspot = 4
    static let download = 5
    static let trayActive = 6
    static let nowPlaying = 7
    static let timer = 8
    static let dragAndDrop = 9
    static let lockScreen = 10
    static let onboarding = 11
}

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
            priority: NotchContentPriority.focus
        )
        static let inactive = NotchContentDescriptor(id: "focus.off")
    }

    enum Network {
        static let bluetooth = NotchContentDescriptor(id: "bluetooth.connected")
        static let hotspot = NotchContentDescriptor(
            id: "hotspot.active",
            priority: NotchContentPriority.hotspot
        )
        static let wifi = NotchContentDescriptor(id: "wifi.connected")
        static let vpn = NotchContentDescriptor(id: "vpn.connected")
    }

    enum Media {
        static let nowPlaying = NotchContentDescriptor(
            id: "nowPlaying",
            priority: NotchContentPriority.nowPlaying
        )
        static let download = NotchContentDescriptor(
            id: "download.active",
            priority: NotchContentPriority.download
        )
        static let timer = NotchContentDescriptor(
            id: "clock.timer",
            priority: NotchContentPriority.timer
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
        static let combined = NotchContentDescriptor(
            id: "dragAndDrop.combined",
            priority: NotchContentPriority.dragAndDrop
        )
        
        static let trayActive = NotchContentDescriptor(
            id: "tray.active",
            priority: NotchContentPriority.trayActive
        )

        static let liveActivityIDs = [
            airDrop.id,
            tray.id,
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

        static let focus = id(Focus.active.id)
        static let focusOff = id(Focus.inactive.id)
        static let hotspot = id(Network.hotspot.id)
        static let nowPlaying = id(Media.nowPlaying.id)
        static let download = id(Media.download.id)
        static let timer = id(Media.timer.id)
        static let bluetooth = id(Network.bluetooth.id)
        static let wifi = id(Network.wifi.id)
        static let vpn = id(Network.vpn.id)
        static let charging = id("charger")
        static let lowPower = id("lowPower")
        static let fullPower = id("fullPower")
        static let hudBrightness = id("hud.brightness")
        static let hudKeyboard = id("hud.keyboard")
        static let hudVolume = id("hud.volume")

        static func id(_ suffix: String) -> String {
            "\(prefix)\(suffix)"
        }
    }
}
