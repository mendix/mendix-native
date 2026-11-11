import Foundation
import Security
import XCTest
@testable import MendixNative

final class KeychainMigrationTests: XCTestCase {
    func testMigrationChangesOnlyAccessibility() {
        var updates = 0
        let migrated = KeychainHelper.migrateAccessibility(
            key: "test-account",
            copyMatching: { query, result in
                let attributes = query as NSDictionary
                XCTAssertEqual(attributes[kSecUseAuthenticationUI] as? String, kSecUseAuthenticationUIFail as String)
                result?.pointee = [kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked] as CFDictionary
                return errSecSuccess
            },
            update: { query, attributes in
                updates += 1
                let identity = query as NSDictionary
                XCTAssertEqual(identity.count, 2)
                XCTAssertEqual(identity[kSecAttrAccount] as? String, "test-account")
                XCTAssertEqual(identity[kSecClass] as? String, kSecClassGenericPassword as String)
                let changes = attributes as NSDictionary
                XCTAssertEqual(changes.count, 1)
                XCTAssertEqual(changes[kSecAttrAccessible] as? String, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
                XCTAssertNil(changes[kSecValueData])
                return errSecSuccess
            }
        )
        XCTAssertTrue(migrated)
        XCTAssertEqual(updates, 1)
    }

    func testInspectionFailuresNeverUpdate() {
        for status in [errSecInteractionNotAllowed, errSecItemNotFound, errSecNotAvailable] {
            XCTAssertFalse(KeychainHelper.migrateAccessibility(
                key: "test-account",
                copyMatching: { _, _ in status },
                update: { _, _ in
                    XCTFail("An unreadable item must not be modified")
                    return errSecSuccess
                }
            ))
        }
    }

    func testMissingAttributesNeverUpdate() {
        XCTAssertFalse(KeychainHelper.migrateAccessibility(
            key: "test-account",
            copyMatching: { _, result in
                result?.pointee = [:] as CFDictionary
                return errSecSuccess
            },
            update: { _, _ in
                XCTFail("An item without accessibility must not be modified")
                return errSecSuccess
            }
        ))
    }

    func testMigratedAndStricterItemsAreNotUpdated() {
        for accessibility in [
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        ] {
            let result = KeychainHelper.migrateAccessibility(
                key: "test-account",
                copyMatching: { _, output in
                    output?.pointee = [kSecAttrAccessible: accessibility] as CFDictionary
                    return errSecSuccess
                },
                update: { _, _ in
                    XCTFail("Already migrated or stricter items must not be changed")
                    return errSecSuccess
                }
            )
            XCTAssertEqual(result, accessibility as String == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
        }
    }

    func testFailedUpdateCanBeRetried() {
        var attempts = 0
        func migrate() -> Bool {
            KeychainHelper.migrateAccessibility(
                key: "test-account",
                copyMatching: { _, result in
                    result?.pointee = [kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked] as CFDictionary
                    return errSecSuccess
                },
                update: { _, _ in
                    attempts += 1
                    return attempts == 1 ? errSecInteractionNotAllowed : errSecSuccess
                }
            )
        }
        XCTAssertFalse(migrate())
        XCTAssertTrue(migrate())
        XCTAssertEqual(attempts, 2)
    }
}
