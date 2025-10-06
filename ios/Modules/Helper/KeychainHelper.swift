import Foundation

public class KeychainHelper {
    
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
