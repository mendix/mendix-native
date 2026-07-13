import Foundation

public class SessionCookieStore {

    // MARK: - Private properties
    private static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.mendix.app"
    private static let storageKey = bundleIdentifier + "sessionCookies"
    private static let queue = DispatchQueue(label: bundleIdentifier + ".session-cookie-store", qos: .utility)

    // MARK: - Public API
    public static func restore() {

        guard let cookies = get(key: storageKey) else {
            NSLog("SessionCookieStore: No cookies to restore")
            return
        }

        let storage = HTTPCookieStorage.shared
        let existing = Set(storage.cookies ?? [])
        cookies.filter { !existing.contains($0) }.forEach { storage.setCookie($0) }

        clear()
    }

    public static func persist() {
        queue.async {
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
            let storeQuery = [kSecClass: kSecClassGenericPassword, kSecAttrAccount: key, kSecValueData: data] as CFDictionary
            let status = SecItemAdd(storeQuery, nil)
            if status != noErr {
                NSLog("SessionCookieStore: Failed to persist session cookies with status: \(status)")
            }
        } catch {
            NSLog("SessionCookieStore: Failed to persist session cookies: \(error.localizedDescription)")
        }
    }

    private static func get(key: String) -> [HTTPCookie]? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecUseAuthenticationUI: kSecUseAuthenticationUIFail
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecInteractionNotAllowed {
            // Oversized/blocked item — remove so it never prompts again
            NSLog("SessionCookieStore: Blocked legacy item detected, clearing")
            clear(key: key)
            return nil
        } else if status == errSecSuccess, let data = item as? Data {
            do {
                let cookies = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, HTTPCookie.self], from: data) as? [HTTPCookie]
                return cookies
            } catch {
                // Unarchiving failed (corrupt/oversized blob) — self-heal by removing
                NSLog("SessionCookieStore: Failed to deserialize legacy cookies, clearing: \(error.localizedDescription)")
                clear(key: key)
                return nil
            }
        } else if status != errSecItemNotFound {
            // Any other unreadable state — delete to prevent repeated failures
            NSLog("SessionCookieStore: Unreadable legacy item (status: \(status)), clearing")
            clear(key: key)
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
