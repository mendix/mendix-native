import Foundation
import React
import React_RCTAppDelegate

@objcMembers
public class NativeFsModule: NSObject {
    
    private static var encryptionEnabled = false
    
    // Error constants
    private static let ERROR_SAVE_FAILED = "ERROR_SAVE_FAILED"
    private static let ERROR_READ_FAILED = "ERROR_READ_FAILED"
    private static let ERROR_MOVE_FAILED = "ERROR_MOVE_FAILED"
    private static let ERROR_DELETE_FAILED = "ERROR_DELETE_FAILED"
    private static let ERROR_SERIALIZATION_FAILED = "ERROR_SERIALIZATION_FAILED"
    private static let INVALID_PATH = "INVALID_PATH"
    
    private static let NativeFsErrorDomain = "com.mendix.mendixnative.nativefsmodule"
    
    public static func setEncryptionEnabled(_ enabled: Bool) {
        encryptionEnabled = enabled
    }
    
    private static func formatError(_ message: String) -> String {
        return "\(String(describing: NativeFsModule.self)): \(message)"
    }
    
    private func readBlobRefAsData(_ blob: [String: Any]) -> Data? {
        guard let blobManager = ReactNative.instance.bridge?.module(for: RCTBlobManager.self) as? RCTBlobManager else {
            return nil
        }
        return blobManager.resolve(blob)
    }
    
    private func readDataAsBlobRef(_ data: Data) -> [String: Any]? {
        guard let blobManager = ReactNative.instance.bridge?.module(for: RCTBlobManager.self) as? RCTBlobManager else {
            return nil
        }
        
        let blobId = blobManager.store(data)
        return [
            "blobId": blobId as Any,
            "offset": 0,
            "length": data.count
        ]
    }
    
    static func readData(_ filePath: String) -> Data? {
        guard FileManager.default.fileExists(atPath: filePath) else {
            return nil
        }
        
        do {
            return try Data(contentsOf: URL(fileURLWithPath: filePath), options: .mappedRead)
        } catch {
            return nil
        }
    }
    
    static func readJson(_ filePath: String, error: NSErrorPointer) -> [String: Any]? {
        guard let data = readData(filePath) else {
            return nil
        }
        
        do {
            let result = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            return result as? [String: Any]
        } catch let jsonError {
            error?.pointee = jsonError as NSError
            return nil
        }
    }
    
    static func save(_ data: Data, filepath: String, error: NSErrorPointer) -> Bool {
        let directoryURL = URL(fileURLWithPath: (filepath as NSString).deletingLastPathComponent)
        
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch let directoryError {
            error?.pointee = directoryError as NSError
            return false
        }
        
        var options: Data.WritingOptions = .atomic
        if encryptionEnabled {
            options = [.atomic, .completeFileProtection]
        }
        
        do {
            try data.write(to: URL(fileURLWithPath: filepath), options: options)
            return true
        } catch let writeError {
            error?.pointee = writeError as NSError
            return false
        }
    }
    
    static func move(_ filepath: String, newPath: String, error: NSErrorPointer) -> Bool {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: filepath) else {
            error?.pointee = NSError(domain: NativeFsErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "File does not exist"])
            return false
        }
        
        let directoryURL = URL(fileURLWithPath: (newPath as NSString).deletingLastPathComponent)
        
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch let directoryError {
            error?.pointee = directoryError as NSError
            return false
        }
        
        do {
            try fileManager.moveItem(atPath: filepath, toPath: newPath)
            return true
        } catch let moveError {
            error?.pointee = moveError as NSError
            return false
        }
    }
    
    static func remove(_ filepath: String, error: NSErrorPointer) -> Bool {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: filepath) else {
            return false
        }
        
        do {
            try fileManager.removeItem(atPath: filepath)
            return true
        } catch let removeError {
            error?.pointee = removeError as NSError
            return false
        }
    }
    
    static func ensureWhiteListedPath(_ paths: [String], error: NSErrorPointer) -> Bool {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
        let tempPath = (NSTemporaryDirectory() as NSString).standardizingPath
        
        for path in paths {
            if !path.hasPrefix(documentsPath) &&
                !path.hasPrefix(cachesPath) &&
                !path.hasPrefix(tempPath) {
                error?.pointee = NSError(
                    domain: NativeFsErrorDomain,
                    code: 999,
                    userInfo: [NSLocalizedDescriptionKey: "The path \(path) does not point to the documents directory"]
                )
                return false
            }
        }
        return true
    }
    
    static func list(_ dirPath: String) -> [String] {
        guard let enumerator = FileManager.default.enumerator(atPath: dirPath) else {
            return []
        }
        return enumerator.allObjects as? [String] ?? []
    }
    
    // MARK: - React Native Bridge Methods
    
    
    public func setEncryptionEnabled(_ enabled: Bool) {
        NativeFsModule.setEncryptionEnabled(enabled)
    }
    
    public func save(
        _ blob: [String: Any],
        filepath: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        
        var error: NSError?
        if !NativeFsModule.ensureWhiteListedPath([filepath], error: &error) {
            reject(NativeFsModule.INVALID_PATH, NativeFsModule.formatError("Path not accessible"), error)
            return
        }
        
        guard let data = readBlobRefAsData(blob) else {
            reject(NativeFsModule.ERROR_READ_FAILED, NativeFsModule.formatError("Failed to read blob"), nil)
            return
        }
        
        if !NativeFsModule.save(data, filepath: filepath, error: &error) {
            reject(NativeFsModule.ERROR_SAVE_FAILED, NativeFsModule.formatError("Save failed"), error)
            return
        }
        
        resolve(nil)
    }
    
    public func read(_ filepath: String,
                     resolve: @escaping RCTPromiseResolveBlock,
                     reject: @escaping RCTPromiseRejectBlock) {
        
        var error: NSError?
        if !NativeFsModule.ensureWhiteListedPath([filepath], error: &error) {
            reject(NativeFsModule.INVALID_PATH, NativeFsModule.formatError("Path not accessible"), error)
            return
        }
        
        guard let data = NativeFsModule.readData(filepath) else {
            resolve(nil)
            return
        }
        
        guard let blob = readDataAsBlobRef(data) else {
            reject(NativeFsModule.ERROR_READ_FAILED, NativeFsModule.formatError("Failed to create blob"), nil)
            return
        }
        
        resolve(blob)
    }
    
    public func move(_ filepath: String,
              newPath: String,
              resolve: @escaping RCTPromiseResolveBlock,
              reject: @escaping RCTPromiseRejectBlock) {
        
        var error: NSError?
        if !NativeFsModule.ensureWhiteListedPath([filepath, newPath], error: &error) {
            reject(NativeFsModule.INVALID_PATH, NativeFsModule.formatError("Path not accessible"), error)
            return
        }
        
        if !NativeFsModule.move(filepath, newPath: newPath, error: &error) {
            reject(NativeFsModule.ERROR_MOVE_FAILED, NativeFsModule.formatError("Failed to move file"), error)
            return
        }
        
        resolve(nil)
    }
    
    public func remove(_ filepath: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        
        var error: NSError?
        if !NativeFsModule.ensureWhiteListedPath([filepath], error: &error) {
            reject(NativeFsModule.INVALID_PATH, NativeFsModule.formatError("Path not accessible"), error)
            return
        }
        
        if !NativeFsModule.remove(filepath, error: &error) {
            reject(NativeFsModule.ERROR_DELETE_FAILED, NativeFsModule.formatError("Failed to delete file"), error)
            return
        }
        
        resolve(nil)
    }
    
    public func list(_ dirPath: String,
              resolve: @escaping RCTPromiseResolveBlock,
              reject: @escaping RCTPromiseRejectBlock) {
        
        var error: NSError?
        if !NativeFsModule.ensureWhiteListedPath([dirPath], error: &error) {
            reject(NativeFsModule.INVALID_PATH, NativeFsModule.formatError("Path not accessible"), error)
            return
        }
        
        resolve(NativeFsModule.list(dirPath))
    }
    
    public func readAsDataURL(_ filePath: String,
                       resolve: @escaping RCTPromiseResolveBlock,
                       reject: @escaping RCTPromiseRejectBlock) {
        
        var error: NSError?
        if !NativeFsModule.ensureWhiteListedPath([filePath], error: &error) {
            reject(NativeFsModule.INVALID_PATH, NativeFsModule.formatError("Path not accessible"), error)
            return
        }
        
        guard let data = NativeFsModule.readData(filePath) else {
            resolve(nil)
            return
        }
        
        let base64String = data.base64EncodedString()
        let dataURL = "data:application/octet-stream;base64,\(base64String)"
        resolve(dataURL)
    }
    
    public func fileExists(_ filepath: String,
                    resolve: @escaping RCTPromiseResolveBlock,
                    reject: @escaping RCTPromiseRejectBlock) {
        
        var error: NSError?
        if !NativeFsModule.ensureWhiteListedPath([filepath], error: &error) {
            reject(NativeFsModule.INVALID_PATH, NativeFsModule.formatError("Path not accessible"), error)
            return
        }
        
        let exists = FileManager.default.fileExists(atPath: filepath)
        resolve(NSNumber(value: exists))
    }
    
    public func readJson(_ filepath: String,
                  resolve: @escaping RCTPromiseResolveBlock,
                  reject: @escaping RCTPromiseRejectBlock) {
        
        var error: NSError?
        if !NativeFsModule.ensureWhiteListedPath([filepath], error: &error) {
            reject(NativeFsModule.INVALID_PATH, NativeFsModule.formatError("Path not accessible"), error)
            return
        }
        
        guard let data = NativeFsModule.readJson(filepath, error: &error) else {
            if let error = error {
                reject(NativeFsModule.ERROR_SERIALIZATION_FAILED, NativeFsModule.formatError("Failed to deserialize JSON"), error)
            } else {
                resolve(nil)
            }
            return
        }
        
        resolve(data)
    }
    
    public func writeJson(_ data: [String: Any],
                   filepath: String,
                   resolve: @escaping RCTPromiseResolveBlock,
                   reject: @escaping RCTPromiseRejectBlock) {
        
        var error: NSError?
        if !NativeFsModule.ensureWhiteListedPath([filepath], error: &error) {
            reject(NativeFsModule.INVALID_PATH, "Path not accessible", error)
            return
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            
            if !NativeFsModule.save(jsonData, filepath: filepath, error: &error) {
                reject(NativeFsModule.ERROR_SAVE_FAILED, NativeFsModule.formatError("Failed to write JSON"), error)
                return
            }
            
            resolve(nil)
        } catch {
            reject(NativeFsModule.ERROR_SERIALIZATION_FAILED, NativeFsModule.formatError("Failed to serialize JSON"), error)
        }
    }
    
    public let constants: NSDictionary = [
        "DocumentDirectoryPath": NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "",
        "SUPPORTS_DIRECTORY_MOVE": true,
        "SUPPORTS_ENCRYPTION": true
    ]
}
