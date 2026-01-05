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
        
        clear() // Clear stored cookies after restoration to avoid any side effects
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
            let storeQuery = [kSecClass: kSecClassGenericPassword, kSecAttrAccount: key, kSecValueData: data] as CFDictionary
            SecItemDelete(storeQuery)
            let status = SecItemAdd(storeQuery, nil)
            if status != noErr {
                NSLog("SessionCookieStore: Failed to persist session cookies with status: \(status)")
            }
        } catch {
            NSLog("SessionCookieStore: Failed to persist session cookies: \(error.localizedDescription)")
        }
    }
    
    private static func get(key: String) -> [HTTPCookie]? {
        do {
            let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrAccount: key, kSecReturnData: true]
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            if status == errSecSuccess, let data = item as? Data {
                let cookies = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, HTTPCookie.self], from: data) as? [HTTPCookie]
                return cookies
            } else {
                NSLog("SessionCookieStore: No session cookies found with status: \(status)")
                return nil
            }
        } catch {
            NSLog("SessionCookieStore: Failed to retrieve session cookies: \(error.localizedDescription)")
            return nil
        }
    }
    
    private static func clear(key: String) {
        let query = [kSecClass: kSecClassGenericPassword, kSecAttrAccount: key, kSecReturnData: true] as CFDictionary
        let status = SecItemDelete(query)
        if status != errSecSuccess {
            NSLog("SessionCookieStore: Failed to clear cookies with status: \(status)")
        }
    }
}
