import AppKit
import Darwin

enum SkyLightSpaceLevel: Int32 {
    case notificationCenterAtScreenLock = 400
}

@MainActor
final class SkyLightOperator {
    static let shared = SkyLightOperator()

    private typealias MainConnectionIDFunction = @convention(c) () -> Int32
    private typealias SpaceCreateFunction = @convention(c) (Int32, Int32, Int32) -> Int32
    private typealias SpaceSetAbsoluteLevelFunction = @convention(c) (Int32, Int32, Int32) -> Int32
    private typealias ShowSpacesFunction = @convention(c) (Int32, CFArray) -> Int32
    private typealias AddWindowsAndRemoveFromSpacesFunction = @convention(c) (Int32, Int32, CFArray, Int32) -> Int32

    private let connection: Int32?
    private let space: Int32?
    private let addWindowsAndRemoveFromSpaces: AddWindowsAndRemoveFromSpacesFunction?

    private init() {
        let frameworkPath = "/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight"

        guard let handle = dlopen(frameworkPath, RTLD_NOW),
              let mainConnectionIDSymbol = dlsym(handle, "SLSMainConnectionID"),
              let spaceCreateSymbol = dlsym(handle, "SLSSpaceCreate"),
              let spaceSetAbsoluteLevelSymbol = dlsym(handle, "SLSSpaceSetAbsoluteLevel"),
              let showSpacesSymbol = dlsym(handle, "SLSShowSpaces"),
              let addWindowsAndRemoveFromSpacesSymbol = dlsym(handle, "SLSSpaceAddWindowsAndRemoveFromSpaces") else {
            connection = nil
            space = nil
            addWindowsAndRemoveFromSpaces = nil
            return
        }

        let mainConnectionID = unsafeBitCast(
            mainConnectionIDSymbol,
            to: MainConnectionIDFunction.self
        )
        let spaceCreate = unsafeBitCast(
            spaceCreateSymbol,
            to: SpaceCreateFunction.self
        )
        let spaceSetAbsoluteLevel = unsafeBitCast(
            spaceSetAbsoluteLevelSymbol,
            to: SpaceSetAbsoluteLevelFunction.self
        )
        let showSpaces = unsafeBitCast(
            showSpacesSymbol,
            to: ShowSpacesFunction.self
        )
        let addWindowsAndRemoveFromSpaces = unsafeBitCast(
            addWindowsAndRemoveFromSpacesSymbol,
            to: AddWindowsAndRemoveFromSpacesFunction.self
        )

        let connection = mainConnectionID()
        let space = spaceCreate(connection, 1, 0)

        _ = spaceSetAbsoluteLevel(
            connection,
            space,
            SkyLightSpaceLevel.notificationCenterAtScreenLock.rawValue
        )
        _ = showSpaces(connection, [space] as CFArray)

        self.connection = connection
        self.space = space
        self.addWindowsAndRemoveFromSpaces = addWindowsAndRemoveFromSpaces
    }

    var isAvailable: Bool {
        connection != nil &&
        space != nil &&
        addWindowsAndRemoveFromSpaces != nil
    }

    func delegateWindow(_ window: NSWindow) {
        guard let connection, let space, let addWindowsAndRemoveFromSpaces else {
            return
        }

        _ = addWindowsAndRemoveFromSpaces(
            connection,
            space,
            [window.windowNumber] as CFArray,
            7
        )
    }
}
