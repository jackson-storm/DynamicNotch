internal import AppKit
import Darwin

enum SkyLightSpaceLevel: Int32, CaseIterable {
    case notchSurface = 2_147_483_647
    case lockScreenOverlay = 400
}

@MainActor
final class SkyLightOperator {
    static let shared = SkyLightOperator()

    private typealias MainConnectionIDFunction = @convention(c) () -> Int32
    private typealias SpaceCreateFunction = @convention(c) (Int32, Int32, Int32) -> Int32
    private typealias SpaceSetAbsoluteLevelFunction = @convention(c) (Int32, Int32, Int32) -> Int32
    private typealias ShowSpacesFunction = @convention(c) (Int32, CFArray) -> Int32
    private typealias AddWindowsAndRemoveFromSpacesFunction = @convention(c) (Int32, Int32, CFArray, Int32) -> Int32
    private typealias CopyManagedDisplaySpacesFunction = @convention(c) (Int32) -> Unmanaged<CFArray>?

    private let connection: Int32?
    private let spaces: [SkyLightSpaceLevel: Int32]
    private let addWindowsAndRemoveFromSpaces: AddWindowsAndRemoveFromSpacesFunction?
    private let copyManagedDisplaySpaces: CopyManagedDisplaySpacesFunction?

    private init() {
        let frameworkPath = "/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight"

        guard let handle = dlopen(frameworkPath, RTLD_NOW),
              let mainConnectionIDSymbol = dlsym(handle, "SLSMainConnectionID"),
              let spaceCreateSymbol = dlsym(handle, "SLSSpaceCreate"),
              let spaceSetAbsoluteLevelSymbol = dlsym(handle, "SLSSpaceSetAbsoluteLevel"),
              let showSpacesSymbol = dlsym(handle, "SLSShowSpaces"),
              let addWindowsAndRemoveFromSpacesSymbol = dlsym(handle, "SLSSpaceAddWindowsAndRemoveFromSpaces") else {
            connection = nil
            spaces = [:]
            addWindowsAndRemoveFromSpaces = nil
            copyManagedDisplaySpaces = nil
            return
        }

        let copyManagedDisplaySpacesSymbol = dlsym(handle, "CGSCopyManagedDisplaySpaces") ??
            dlsym(handle, "SLSCopyManagedDisplaySpaces")

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
        let copyManagedDisplaySpaces = copyManagedDisplaySpacesSymbol.map {
            unsafeBitCast($0, to: CopyManagedDisplaySpacesFunction.self)
        }

        let connection = mainConnectionID()
        var spaces: [SkyLightSpaceLevel: Int32] = [:]

        for level in SkyLightSpaceLevel.allCases {
            let space = spaceCreate(connection, 1, 0)
            guard space != 0 else { continue }

            _ = spaceSetAbsoluteLevel(
                connection,
                space,
                level.rawValue
            )
            _ = showSpaces(connection, [space] as CFArray)
            spaces[level] = space
        }

        self.connection = connection
        self.spaces = spaces
        self.addWindowsAndRemoveFromSpaces = addWindowsAndRemoveFromSpaces
        self.copyManagedDisplaySpaces = copyManagedDisplaySpaces
    }

    var isAvailable: Bool {
        connection != nil &&
        !spaces.isEmpty &&
        addWindowsAndRemoveFromSpaces != nil
    }

    func isFullscreenSpaceActive(on screen: NSScreen) -> Bool {
        guard let connection,
              let copyManagedDisplaySpaces,
              let displayIdentifier = screen.displayUUIDString,
              let managedSpaces = copyManagedDisplaySpaces(connection)?.takeRetainedValue() as? [[String: Any]],
              let displayEntry = managedSpaces.first(where: {
                  guard let identifier = $0["Display Identifier"] as? String else {
                      return false
                  }

                  return identifier.caseInsensitiveCompare(displayIdentifier) == .orderedSame
              }),
              let currentSpace = displayEntry["Current Space"] as? [String: Any],
              let currentSpaceType = currentSpace["type"] as? NSNumber else {
            return false
        }

        return currentSpaceType.intValue == 4
    }

    func delegateWindow(
        _ window: NSWindow,
        to level: SkyLightSpaceLevel = .notchSurface
    ) {
        guard let connection,
              let space = spaces[level],
              let addWindowsAndRemoveFromSpaces else {
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
