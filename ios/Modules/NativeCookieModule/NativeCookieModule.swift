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
    
    public static func persistSessionCookies() {
        SessionCookieStore.persist()
    }
    
    public static func restoreSessionCookies() {
        SessionCookieStore.restore()
    }
    
    final class SessionCookieStore {
        
        private static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.mendix.app"
        private static let storageKey = bundleIdentifier + "sessionCookies"
        private static let queue = DispatchQueue(label: bundleIdentifier + ".session-cookie-store", qos: .utility)
        
        // MARK: - Public API
        public static func restore() {
            
            guard
                let data = UserDefaults.standard.data(forKey: storageKey),
                let cookies = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, HTTPCookie.self], from: data) as? [HTTPCookie]
            else {
                NSLog("SessionCookieStore: No cookies to restore")
                return
            }
            
            let storage = HTTPCookieStorage.shared
            let existing = Set(storage.cookies ?? [])
            
            cookies.filter { !existing.contains($0) }.forEach { storage.setCookie($0) }
            
            // Clear stored cookies after restoration to avoid any side effects
            clear()
        }
        
        public static func persist() {
            queue.async {
                
                let cookies = HTTPCookieStorage.shared.cookies ?? []
                let sessionCookies = cookies.filter { isSessionCookie($0) }
                
                guard !sessionCookies.isEmpty else {
                    clear()
                    NSLog("SessionCookieStore: Clear existing session cookies from storage")
                    return
                }
                
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: sessionCookies, requiringSecureCoding: false)
                    UserDefaults.standard.set(data, forKey: storageKey)
                } catch {
                    NSLog("SessionCookieStore: Failed to persist session cookies: \(error.localizedDescription)")
                }
            }
        }
        
        public static func clear() {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
        
        public static func isSessionCookie(_ cookie: HTTPCookie) -> Bool {
            return cookie.expiresDate == nil
        }
    }
}
