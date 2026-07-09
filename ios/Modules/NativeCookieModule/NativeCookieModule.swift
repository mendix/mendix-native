import Foundation

@objcMembers
public class NativeCookieModule: NSObject {
    public func clearAll(_ promise: Promise) {
        NativeCookieModule.clearAll()
        promise.resolve(nil)
    }

    static func clearAll() {
        let storage = HTTPCookieStorage.shared
        for cookie in (storage.cookies ?? []) {
            storage.deleteCookie(cookie)
        }
        SessionCookieStore.clear()
    }

    // MARK: - Test / diagnostic helpers (DEBUG builds only)
    // These methods are excluded from release builds to prevent cookie injection,
    // session DoS, and keychain information disclosure from arbitrary JS callers.

#if DEBUG
    /// Seeds `count` session cookies (no expiry), each with a `valueSize`-byte value,
    /// into `HTTPCookieStorage.shared`. Used in harness tests to produce blobs of
    /// controlled size without relying on a live server.
    public func seedTestCookies(count: Int, valueSize: Int, promise: Promise) {
        let storage = HTTPCookieStorage.shared
        for i in 0..<count {
            if let cookie = HTTPCookie(properties: [
                .name:   "testCookie\(i)",
                .value:  String(repeating: "X", count: valueSize),
                .domain: "test.mendix.com",
                .path:   "/",
                // no .expires → session cookie (expiresDate == nil)
            ]) {
                storage.setCookie(cookie)
            }
        }
        promise.resolve(nil)
    }

    /// Persists the current session cookies in `HTTPCookieStorage.shared` to the keychain
    /// and resolves the promise once the async write completes.
    public func persistSessionCookies(_ promise: Promise) {
        SessionCookieStore.persist(completion: {
            promise.resolve(nil)
        })
    }

    /// Deletes all cookies from `HTTPCookieStorage.shared` without touching the keychain.
    /// Use this between `persistSessionCookies` and `restoreSessionCookies` to simulate
    /// an app restart.
    public func clearHTTPCookies(_ promise: Promise) {
        let storage = HTTPCookieStorage.shared
        (storage.cookies ?? []).forEach { storage.deleteCookie($0) }
        promise.resolve(nil)
    }

    /// Calls `SessionCookieStore.restore()` and returns the names of every cookie
    /// currently in `HTTPCookieStorage.shared` after the restore.
    public func restoreSessionCookies(_ promise: Promise) {
        SessionCookieStore.restore()
        let names = (HTTPCookieStorage.shared.cookies ?? []).map(\.name)
        promise.resolve(names)
    }

    /// Returns the integer stored in the `_chunkcount` commit-marker keychain item,
    /// or `0` if no chunked write exists (single-item or empty).
    public func getKeychainChunkCount(_ promise: Promise) {
        let bundleId = Bundle.main.bundleIdentifier ?? "com.mendix.app"
        let countKey = bundleId + "sessionCookies_chunkcount"
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: countKey,
            kSecReturnData:  true,
        ]
        var ref: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &ref)
        if status == errSecSuccess,
           let data  = ref as? Data,
           let str   = String(data: data, encoding: .utf8),
           let count = Int(str) {
            promise.resolve(NSNumber(value: count))
        } else {
            promise.resolve(NSNumber(value: 0))
        }
    }
#endif
}
