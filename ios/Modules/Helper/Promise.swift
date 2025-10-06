import Foundation
import React

@objcMembers
public class Promise: NSObject {
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
