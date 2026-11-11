import Foundation
import Security

public class SessionCookieStore {

    // MARK: - Private properties
    private static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.mendix.app"
    private static let storageKey = bundleIdentifier + "sessionCookies"
    private static let queue = DispatchQueue(label: bundleIdentifier + ".session-cookie-store", qos: .utility)

    // MARK: - Public API
    public static func restore() {
        restore(
            storage: HTTPCookieStorage.shared,
            read: { get(key: storageKey) },
            remove: { clear() }
        )
    }

    static func restore(
        storage: HTTPCookieStorage,
        read: () -> (cookies: [HTTPCookie], migrated: Bool)?,
        remove: () -> Void
    ) {
        guard let restored = read() else {
            NSLog("SessionCookieStore: No cookies to restore")
            return
        }

        let existing = Set(storage.cookies ?? [])
        restored.cookies.filter { !existing.contains($0) }.forEach { storage.setCookie($0) }

        if restored.migrated {
            remove()
        }
    }

    public static func persist() {
        persist(completion: {})
    }

    static func persist(completion: @escaping () -> Void) {
        queue.async {
            defer { completion() }
            let sessionCookies = HTTPCookieStorage.shared.cookies?.filter { isSessionCookie($0) } ?? []
            guard !sessionCookies.isEmpty else {
                clear()
                NSLog("SessionCookieStore: Clear existing session cookies from storage")
                return
            }
            set(key: storageKey, cookies: sessionCookies)
        }
    }

    public static func clear() {
        clear(key: storageKey)
    }

    // MARK: - Private API
    private static func isSessionCookie(_ cookie: HTTPCookie) -> Bool {
        return cookie.expiresDate == nil
    }

    private static func set(key: String, cookies: [HTTPCookie]) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: false)
            clear(key: key)
            let storeQuery = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: key,
                kSecValueData: data,
                kSecAttrAccessible: KeychainHelper.accessibility
            ] as CFDictionary
            let status = SecItemAdd(storeQuery, nil)
            if status != noErr {
                NSLog("SessionCookieStore: Failed to persist session cookies with status: \(status)")
            }
        } catch {
            NSLog("SessionCookieStore: Failed to persist session cookies: \(error.localizedDescription)")
        }
    }

    static func get(
        key: String,
        copyMatching: (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = SecItemCopyMatching,
        migrate: (String) -> Bool = { KeychainHelper.migrateAccessibility(key: $0) },
        remove: (String) -> Void = { clear(key: $0) }
    ) -> (cookies: [HTTPCookie], migrated: Bool)? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecUseAuthenticationUI: kSecUseAuthenticationUIFail
        ]
        var item: CFTypeRef?
        let status = copyMatching(query as CFDictionary, &item)

        if status == errSecInteractionNotAllowed {
            NSLog("SessionCookieStore: Item inaccessible (device locked), skipping restore")
            return nil
        } else if status == errSecSuccess, let data = item as? Data {
            let result = ObjCExceptionCatcher.catchException {
                do {
                    let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
                    // HTTPCookie uses NSCoding, matching the existing non-secure archive format.
                    unarchiver.requiresSecureCoding = false
                    defer { unarchiver.finishDecoding() }
                    return unarchiver.decodeObject(
                        of: [NSArray.self, HTTPCookie.self],
                        forKey: NSKeyedArchiveRootObjectKey
                    )
                } catch {
                    NSLog("SessionCookieStore: Cookie decoding failed with code: \((error as NSError).code)")
                    return nil
                }
            }

            guard let cookies = result as? [HTTPCookie] else {
                NSLog("SessionCookieStore: Failed to deserialize cookies, clearing")
                remove(key)
                return nil
            }
            return (cookies, migrate(key))
        } else if status != errSecItemNotFound {
            // Any other unreadable state — delete to prevent repeated failures
            NSLog("SessionCookieStore: Unreadable legacy item (status: \(status)), clearing")
            remove(key)
            return nil
        } else {
            NSLog("SessionCookieStore: No session cookies found")
            return nil
        }
    }

    private static func clear(key: String) {
        let query = [kSecClass: kSecClassGenericPassword, kSecAttrAccount: key] as CFDictionary
        let status = SecItemDelete(query)
        if status != errSecSuccess && status != errSecItemNotFound {
            NSLog("SessionCookieStore: Failed to clear cookies with status: \(status)")
        }
    }
}
