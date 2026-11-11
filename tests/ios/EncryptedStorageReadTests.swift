import Foundation
import Security
import XCTest
@testable import MendixNative

final class EncryptedStorageReadTests: XCTestCase {
    func testFailedMigrationStillReturnsReadableValue() {
        for strict in [true, false] {
            var resolved = false
            var migrated = false
            let promise = Promise(
                resolve: { value in
                    resolved = true
                    XCTAssertEqual(value as? String, "unchanged-password")
                },
                reject: { _, _, _ in XCTFail("Migration failure must not discard a readable value") }
            )
            EncryptedStorage().readItem(
                key: "test-password",
                promise: promise,
                strict: strict,
                copyMatching: { _, result in
                    result?.pointee = Data("unchanged-password".utf8) as CFData
                    return errSecSuccess
                },
                migrate: { key in
                    XCTAssertEqual(key, "test-password")
                    migrated = true
                    return false
                }
            )
            XCTAssertTrue(migrated)
            XCTAssertTrue(resolved)
        }
    }

    func testStrictReadRejectsInaccessibleAndFailedReads() {
        for status in [errSecInteractionNotAllowed, errSecNotAvailable, errSecAuthFailed] {
            var rejectedCode: String?
            let promise = Promise(
                resolve: { _ in XCTFail("An inaccessible item must not appear absent") },
                reject: { code, _, _ in rejectedCode = code }
            )
            EncryptedStorage().readItem(
                key: "test-password",
                promise: promise,
                strict: true,
                copyMatching: { query, _ in
                    XCTAssertEqual(
                        (query as NSDictionary)[kSecUseAuthenticationUI] as? String,
                        kSecUseAuthenticationUIFail as String
                    )
                    return status
                }
            )
            XCTAssertEqual(rejectedCode, String(status))
        }
    }

    func testBothReadModesResolveMissingItemsAsNull() {
        for strict in [true, false] {
            var resolved = false
            let promise = Promise(
                resolve: { value in
                    resolved = true
                    XCTAssertTrue(value is NSNull)
                },
                reject: { _, _, _ in XCTFail("An absent item must resolve") }
            )
            EncryptedStorage().readItem(
                key: "test-password",
                promise: promise,
                strict: strict,
                copyMatching: { _, _ in errSecItemNotFound }
            )
            XCTAssertTrue(resolved)
        }
    }

    func testLegacyReadStillResolvesInaccessibleItemsAsNull() {
        var resolved = false
        let promise = Promise(
            resolve: { value in
                resolved = true
                XCTAssertTrue(value is NSNull)
            },
            reject: { _, _, _ in XCTFail("The legacy contract must not change") }
        )
        EncryptedStorage().readItem(
            key: "test-password",
            promise: promise,
            strict: false,
            copyMatching: { _, _ in errSecInteractionNotAllowed }
        )
        XCTAssertTrue(resolved)
    }

    func testInvalidUTF8RejectsInsteadOfAppearingAbsent() {
        for strict in [true, false] {
            var rejectedCode: String?
            let promise = Promise(
                resolve: { _ in XCTFail("Malformed data must not appear absent") },
                reject: { code, _, _ in rejectedCode = code }
            )
            EncryptedStorage().readItem(
                key: "test-password",
                promise: promise,
                strict: strict,
                copyMatching: { _, result in
                    result?.pointee = Data([0xff]) as CFData
                    return errSecSuccess
                }
            )
            XCTAssertEqual(rejectedCode, String(errSecDecode))
        }
    }
}
