import Foundation
import Security
import XCTest
@testable import MendixNative

final class SessionCookieStoreTests: XCTestCase {
    private let cookieName = "MOO2540-test-session"
    private var storageKey: String {
        (Bundle.main.bundleIdentifier ?? "com.mendix.app") + "sessionCookies"
    }

    private func cookie() throws -> HTTPCookie {
        try XCTUnwrap(HTTPCookie(properties: [
            .name: cookieName,
            .value: "test-session-value",
            .domain: "moo2540.invalid",
            .path: "/"
        ]))
    }

    private func persistAndWait() {
        let completed = expectation(description: "Cookie persistence completed")
        SessionCookieStore.persist { completed.fulfill() }
        wait(for: [completed], timeout: 5)
    }

    private func removeInMemoryCookies() {
        for cookie in HTTPCookieStorage.shared.cookies ?? [] {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }

    override func setUp() {
        super.setUp()
        removeInMemoryCookies()
        SessionCookieStore.clear()
    }

    override func tearDown() {
        removeInMemoryCookies()
        SessionCookieStore.clear()
        super.tearDown()
    }

    func testPersistenceUsesDeviceOnlyAccessibilityAndRestoreConsumesCopy() throws {
        let original = try cookie()
        HTTPCookieStorage.shared.setCookie(original)
        persistAndWait()

        var result: CFTypeRef?
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: storageKey,
            kSecReturnAttributes: true
        ] as CFDictionary
        XCTAssertEqual(SecItemCopyMatching(query, &result), errSecSuccess)
        let attributes = try XCTUnwrap(result as? [String: Any])
        XCTAssertEqual(
            attributes[kSecAttrAccessible as String] as? String,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        )

        removeInMemoryCookies()
        SessionCookieStore.restore()
        let restored = (HTTPCookieStorage.shared.cookies ?? []).filter { $0.name == cookieName }
        XCTAssertEqual(restored.count, 1)
        XCTAssertEqual(restored.first?.value, original.value)
        XCTAssertNil(SessionCookieStore.get(key: storageKey))
        SessionCookieStore.restore()
        XCTAssertEqual((HTTPCookieStorage.shared.cookies ?? []).filter { $0.name == cookieName }.count, 1)
    }

    func testEmptyPersistenceAndExplicitClearRemoveStoredCopy() throws {
        HTTPCookieStorage.shared.setCookie(try cookie())
        persistAndWait()
        XCTAssertNotNil(SessionCookieStore.get(key: storageKey))
        removeInMemoryCookies()
        persistAndWait()
        XCTAssertNil(SessionCookieStore.get(key: storageKey))

        HTTPCookieStorage.shared.setCookie(try cookie())
        persistAndWait()
        SessionCookieStore.clear()
        XCTAssertNil(SessionCookieStore.get(key: storageKey))
    }

    func testPersistenceExcludesPersistentCookies() throws {
        let session = try cookie()
        let persistent = try XCTUnwrap(HTTPCookie(properties: [
            .name: "MOO2540-test-persistent",
            .value: "persistent-value",
            .domain: "moo2540.invalid",
            .path: "/",
            .expires: Date().addingTimeInterval(3600)
        ]))
        HTTPCookieStorage.shared.setCookie(session)
        HTTPCookieStorage.shared.setCookie(persistent)
        persistAndWait()

        let stored = try XCTUnwrap(SessionCookieStore.get(key: storageKey))
        XCTAssertEqual(stored.cookies.count, 1)
        XCTAssertEqual(stored.cookies.first?.name, cookieName)

        removeInMemoryCookies()
        HTTPCookieStorage.shared.setCookie(persistent)
        persistAndWait()
        XCTAssertNil(SessionCookieStore.get(key: storageKey))
    }

    func testLegacyCookieMigrationPreservesPayload() throws {
        let original = try cookie()
        let data = try NSKeyedArchiver.archivedData(withRootObject: [original], requiringSecureCoding: false)
        let attributes = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: storageKey,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
        ] as CFDictionary
        XCTAssertEqual(SecItemAdd(attributes, nil), errSecSuccess)
        let restored = try XCTUnwrap(SessionCookieStore.get(key: storageKey))
        XCTAssertTrue(restored.migrated)
        XCTAssertEqual(restored.cookies.first?.value, original.value)
        var result: CFTypeRef?
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: storageKey,
            kSecReturnData: true
        ] as CFDictionary
        XCTAssertEqual(SecItemCopyMatching(query, &result), errSecSuccess)
        XCTAssertEqual(result as? Data, data)
        let attributeQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: storageKey,
            kSecReturnAttributes: true
        ] as CFDictionary
        XCTAssertEqual(SecItemCopyMatching(attributeQuery, &result), errSecSuccess)
        let migratedAttributes = try XCTUnwrap(result as? [String: Any])
        XCTAssertEqual(
            migratedAttributes[kSecAttrAccessible as String] as? String,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        )
    }

    func testFailedMigrationRestoresCookiesButDoesNotConsumeCopy() throws {
        let original = try cookie()
        let data = try NSKeyedArchiver.archivedData(withRootObject: [original], requiringSecureCoding: false)
        var removed = false
        let restored = SessionCookieStore.get(
            key: storageKey,
            copyMatching: { _, output in
                output?.pointee = data as CFData
                return errSecSuccess
            },
            migrate: { _ in false },
            remove: { _ in removed = true }
        )
        XCTAssertNotNil(restored)
        SessionCookieStore.restore(
            storage: HTTPCookieStorage.shared,
            read: { restored },
            remove: { removed = true }
        )
        XCTAssertFalse(removed)
        XCTAssertEqual((HTTPCookieStorage.shared.cookies ?? []).first { $0.name == cookieName }?.value, original.value)

        SessionCookieStore.restore(
            storage: HTTPCookieStorage.shared,
            read: { ([original], true) },
            remove: { removed = true }
        )
        XCTAssertTrue(removed)
        XCTAssertEqual((HTTPCookieStorage.shared.cookies ?? []).filter { $0.name == cookieName }.count, 1)
    }

    func testLockedAndMissingItemsAreNotMigratedOrDeleted() {
        for status in [errSecInteractionNotAllowed, errSecItemNotFound] {
            XCTAssertNil(SessionCookieStore.get(
                key: storageKey,
                copyMatching: { _, _ in status },
                migrate: { _ in
                    XCTFail("An inaccessible or absent item must not migrate")
                    return false
                },
                remove: { _ in XCTFail("An inaccessible or absent item must not be deleted") }
            ))
        }
    }

    func testCorruptArchiveKeepsExistingCleanupBehavior() {
        var removed = false
        XCTAssertNil(SessionCookieStore.get(
            key: storageKey,
            copyMatching: { _, output in
                output?.pointee = Data([0, 1, 2]) as CFData
                return errSecSuccess
            },
            migrate: { _ in
                XCTFail("Corrupt cookies must not migrate")
                return false
            },
            remove: { _ in removed = true }
        ))
        XCTAssertTrue(removed)
    }
}
