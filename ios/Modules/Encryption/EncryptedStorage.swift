
import Foundation
import Security

@objcMembers public class EncryptedStorage: NSObject {
    
    public static let isEncrypted = true
    
    public func setItem(key: String, value: String, promise: Promise) {
        guard let dataFromValue = value.data(using: .utf8) else {
            promise.reject("An error occured while saving value", errorCode: 0)
            return
        }
        
        let storeQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: dataFromValue,
            kSecAttrAccessible: KeychainHelper.accessibility
        ] as CFDictionary
        
        let identity = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ] as CFDictionary
        let deleteStatus = SecItemDelete(identity)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            promise.reject("An error occured while saving value", errorCode: Int(deleteStatus))
            return
        }
        
        let status = SecItemAdd(storeQuery, nil)
        
        if status == noErr {
            promise.resolve(value)
        } else {
            promise.reject("An error occured while saving value", errorCode: Int(status))
        }
    }
    
    public func getItem(key: String, promise: Promise) {
        readItem(key: key, promise: promise, strict: false)
    }

    public func getItemStrict(key: String, promise: Promise) {
        readItem(key: key, promise: promise, strict: true)
    }

    @nonobjc func readItem(
        key: String,
        promise: Promise,
        strict: Bool,
        copyMatching: (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = SecItemCopyMatching,
        migrate: (String) -> Bool = { KeychainHelper.migrateAccessibility(key: $0) }
    ) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: kCFBooleanTrue as Any,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecUseAuthenticationUI: kSecUseAuthenticationUIFail
        ] as CFDictionary
        var dataRef: CFTypeRef?
        let status = copyMatching(query, &dataRef)
        if status == errSecInteractionNotAllowed && !strict {
            // Device locked or item requires auth — don't delete, resolve as absent
            promise.resolve(NSNull())
        } else if status == errSecSuccess {
            guard let data = dataRef as? Data, let value = String(data: data, encoding: .utf8) else {
                promise.reject("An error occured while retrieving value", errorCode: Int(errSecDecode))
                return
            }
            _ = migrate(key)
            promise.resolve(value)
        } else if status == errSecItemNotFound {
            promise.resolve(NSNull())
        } else {
            promise.reject("An error occured while retrieving value", errorCode: Int(status))
        }
    }
    
    public func removeItem(key: String, promise: Promise) {
        
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: kCFBooleanTrue as Any
        ] as CFDictionary
        
        let status = SecItemDelete(query)
        
        if status == noErr || status == errSecItemNotFound {
            promise.resolve(key)
        } else {
            promise.reject("An error occured while removing value", errorCode: Int(status))
        }
    }
    
    public func clear(promise: Promise) {
        let secureItems: [CFString] = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        
        for item in secureItems {
            SecItemDelete([kSecClass: item] as CFDictionary)
        }
        promise.resolve(nil)
    }
}
