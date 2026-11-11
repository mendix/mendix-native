import Foundation
import Security

public class KeychainHelper {

    static let accessibility = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    static func migrateAccessibility(
        key: String,
        copyMatching: (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = SecItemCopyMatching,
        update: (CFDictionary, CFDictionary) -> OSStatus = SecItemUpdate
    ) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnAttributes: true,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecUseAuthenticationUI: kSecUseAuthenticationUIFail
        ]
        var result: CFTypeRef?
        let readStatus = copyMatching(query as CFDictionary, &result)
        guard readStatus == errSecSuccess else {
            NSLog("KeychainHelper: Failed to inspect accessibility with status: \(readStatus)")
            return false
        }
        guard let attributes = result as? [String: Any],
              let current = attributes[kSecAttrAccessible as String] as? String else {
            NSLog("KeychainHelper: Missing accessibility attribute")
            return false
        }
        if current == accessibility as String {
            return true
        }
        // Only migrate the old default; do not weaken explicitly stricter items.
        guard current == kSecAttrAccessibleWhenUnlocked as String else {
            NSLog("KeychainHelper: Preserving non-default accessibility")
            return false
        }
        let identity = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ] as CFDictionary
        let status = update(identity, [kSecAttrAccessible: accessibility] as CFDictionary)
        if status != errSecSuccess {
            NSLog("KeychainHelper: Failed to migrate accessibility with status: \(status)")
        }
        return status == errSecSuccess
    }
    
    public static func clear() {
        clear(scopeKey: MxConfiguration.appName)
    }
    
    public static func clear(scopeKey: String?) {
        let keys = [
            Self.toAppScopeKey("token", scope: scopeKey),
            Self.toAppScopeKey("session", scope: scopeKey)
        ]
        
        for key in keys {
            deleteKeychainItem(withKey: key)
        }
    }
    
    private static func toAppScopeKey(_ key: String, scope: String? = nil) -> String {
        guard let scope, !scope.isEmpty else {
            return key
        }
        return "\(scope)_\(key)"
    }
    
    private static func deleteKeychainItem(withKey key: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: kCFBooleanTrue as Any
        ]
        SecItemDelete(query as CFDictionary)
    }
}
