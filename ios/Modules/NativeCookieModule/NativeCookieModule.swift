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
    /// Writes `count` synthetic session cookies with `valueSize`-byte values directly
    /// to the keychain (bypasses HTTPCookieStorage) and resolves once the write completes.
    public func persistTestCookies(count: Int, valueSize: Int, promise: Promise) {
        SessionCookieStore.persistTestCookies(count: count, valueSize: valueSize) {
            promise.resolve(nil)
        }
    }

    public func restoreSessionCookies(_ promise: Promise) {
        let names = SessionCookieStore.restoreTestCookieNames()
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
