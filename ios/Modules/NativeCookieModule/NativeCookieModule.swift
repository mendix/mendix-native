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
}
