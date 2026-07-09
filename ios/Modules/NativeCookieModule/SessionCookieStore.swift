import Foundation

public class SessionCookieStore {

    // MARK: - Private properties
    private static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.mendix.app"
    private static let storageKey = bundleIdentifier + "sessionCookies"
    private static let queue = DispatchQueue(label: bundleIdentifier + ".session-cookie-store", qos: .utility)
    private static let chunkSize: Int = 64 * 1024
    private static let maxChunks: Int = 1000

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

#if DEBUG
    /// Persist variant that calls `completion` once the keychain write finishes.
    /// Only compiled in DEBUG builds; used by the harness test bridge to await completion.
    public static func persist(completion: @escaping () -> Void) {
        queue.async {
            let sessionCookies = HTTPCookieStorage.shared.cookies?.filter { isSessionCookie($0) } ?? []
            guard !sessionCookies.isEmpty else {
                clear()
                NSLog("SessionCookieStore: Clear existing session cookies from storage")
                completion()
                return
            }
            set(key: storageKey, cookies: sessionCookies)
            completion()
        }
    }
#endif

    public static func clear() {
        clearAllChunks(key: storageKey)
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
            clearAllChunks(key: key)

            if data.count <= chunkSize {
                let storeQuery = [kSecClass: kSecClassGenericPassword, kSecAttrAccount: key, kSecValueData: data] as CFDictionary
                let status = SecItemAdd(storeQuery, nil)
                if status != noErr {
                    NSLog("SessionCookieStore: Failed to persist session cookies with status: \(status)")
                }
            } else {
                let chunkCount = min((data.count + chunkSize - 1) / chunkSize, maxChunks)

                var writtenChunkKeys: [String] = []
                var failed = false

                for i in 0..<chunkCount {
                    let start = i * chunkSize
                    let end = min(start + chunkSize, data.count)
                    let chunkKey = key + "_chunk_\(i)"
                    let chunkQuery = [kSecClass: kSecClassGenericPassword, kSecAttrAccount: chunkKey, kSecValueData: Data(data[start..<end])] as CFDictionary
                    let status = SecItemAdd(chunkQuery, nil)
                    if status != noErr {
                        NSLog("SessionCookieStore: Failed to write chunk \(i) with status: \(status)")
                        failed = true
                        break
                    }
                    writtenChunkKeys.append(chunkKey)
                }

                guard !failed else {
                    for chunkKey in writtenChunkKeys {
                        SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrAccount: chunkKey] as CFDictionary)
                    }
                    return
                }

                // Commit marker written last — its presence guarantees all chunks are present
                let countKey = key + "_chunkcount"
                let countData = "\(chunkCount)".data(using: .utf8)!
                let countQuery = [kSecClass: kSecClassGenericPassword, kSecAttrAccount: countKey, kSecValueData: countData] as CFDictionary
                let countStatus = SecItemAdd(countQuery, nil)
                if countStatus != noErr {
                    // Rollback
                    for chunkKey in writtenChunkKeys {
                        SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrAccount: chunkKey] as CFDictionary)
                    }
                    NSLog("SessionCookieStore: Failed to write chunk count marker (status: \(countStatus)), rolled back")
                }
            }
        } catch {
            NSLog("SessionCookieStore: Failed to persist session cookies: \(error.localizedDescription)")
        }
    }

    private static func get(key: String) -> [HTTPCookie]? {
        let countKey = key + "_chunkcount"
        let countQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: countKey,
            kSecReturnData: true,
            kSecUseAuthenticationUI: kSecUseAuthenticationUIFail
        ]
        var countRef: CFTypeRef?
        let countStatus = SecItemCopyMatching(countQuery as CFDictionary, &countRef)

        if countStatus == errSecSuccess,
           let countData = countRef as? Data,
           let countStr = String(data: countData, encoding: .utf8),
           let chunkCount = Int(countStr) {

            var assembled = Data()
            for i in 0..<chunkCount {
                let chunkKey = key + "_chunk_\(i)"
                let chunkQuery: [CFString: Any] = [
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrAccount: chunkKey,
                    kSecReturnData: true,
                    kSecUseAuthenticationUI: kSecUseAuthenticationUIFail
                ]
                var chunkRef: CFTypeRef?
                let chunkStatus = SecItemCopyMatching(chunkQuery as CFDictionary, &chunkRef)
                guard chunkStatus == errSecSuccess, let chunkData = chunkRef as? Data else {
                    NSLog("SessionCookieStore: Failed to read chunk \(i) (status: \(chunkStatus)), discarding chunked set")
                    clearAllChunks(key: key)
                    return nil
                }
                assembled.append(chunkData)
            }
            do {
                let cookies = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, HTTPCookie.self], from: assembled) as? [HTTPCookie]
                return cookies
            } catch {
                NSLog("SessionCookieStore: Failed to deserialize chunked cookies, clearing: \(error.localizedDescription)")
                clearAllChunks(key: key)
                return nil
            }
        }

        // --- Legacy single-item format (backward compat on read) ---
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
                NSLog("SessionCookieStore: Failed to deserialize legacy cookies, clearing: \(error.localizedDescription)")
                clear(key: key)
                return nil
            }
        } else if status != errSecItemNotFound {
            NSLog("SessionCookieStore: Unreadable legacy item (status: \(status)), clearing")
            clear(key: key)
            return nil
        } else {
            NSLog("SessionCookieStore: No session cookies found")
            return nil
        }
    }

    private static func clear(key: String) {
        let query = [kSecClass: kSecClassGenericPassword, kSecAttrAccount: key, kSecReturnData: true] as CFDictionary
        let status = SecItemDelete(query)
        if status != errSecSuccess && status != errSecItemNotFound {
            NSLog("SessionCookieStore: Failed to clear cookies with status: \(status)")
        }
    }

    private static func clearAllChunks(key: String) {
        SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrAccount: key + "_chunkcount"] as CFDictionary)
        for i in 0..<maxChunks {
            let st = SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrAccount: key + "_chunk_\(i)"] as CFDictionary)
            if st == errSecItemNotFound { break }
        }
    }
}
