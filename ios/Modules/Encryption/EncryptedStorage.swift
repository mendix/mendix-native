
import Foundation
import React

//TODO: Move to separate file
@objcMembers public class Promise: NSObject {
    public let resolve: RCTPromiseResolveBlock
    public let reject: RCTPromiseRejectBlock
    
    public init(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        self.resolve = resolve
        self.reject = reject
    }
    
    public func reject(_ message: String, errorCode: Int) {
        let domain = Bundle.main.bundleIdentifier ?? "EncryptedStorage"
        let error = NSError(domain: domain, code: errorCode, userInfo: nil)
        let errorCode = "\(error.code)"
        let errorMessage = "RNEncryptedStorageError: \(message)"
        reject(errorCode, errorMessage, error)
    }
    
    public static func instance(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Promise {
        return Promise(resolve: resolve, reject: reject)
    }
}

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
            kSecValueData: dataFromValue
        ] as CFDictionary
        
        SecItemDelete(storeQuery)
        
        let status = SecItemAdd(storeQuery, nil)
        
        if status == noErr {
            promise.resolve(value)
        } else {
            promise.reject("An error occured while saving value", errorCode: Int(status))
        }
    }
    
    public func getItem(key: String, promise: Promise) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: kCFBooleanTrue as Any,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        var dataRef: CFTypeRef?
        let status = SecItemCopyMatching(query, &dataRef)
        if status == errSecSuccess {
            guard let data = dataRef as? Data, let value = String(data: data, encoding: .utf8) else {
                promise.reject("An error occured while retrieving value", errorCode: Int(status))
                return
            }
            promise.resolve(value)
        } else if status == errSecItemNotFound {
            promise.resolve(nil)
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
    
    public func clear(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
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
        resolve(nil)
    }
}

//Checked
