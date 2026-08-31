import Contacts
import XCTest
@testable import DynamicNotch

@MainActor
final class SettingsPermissionControllerContactsTests: XCTestCase {

    func testPermissionItemsIncludeContactsPermission() throws {
        let controller = SettingsPermissionController(notificationCenter: NotificationCenter())

        let permission = try XCTUnwrap(
            controller.permissionItems.first {
                $0.kind.rawValue == "contacts"
            }
        )

        XCTAssertEqual(
            permission.isGranted,
            CNContactStore.authorizationStatus(for: .contacts) == .authorized
        )
    }
}
