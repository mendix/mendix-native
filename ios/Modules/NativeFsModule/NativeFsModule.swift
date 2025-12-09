import Foundation
import React

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
    
    private func getBlobManager() -> RCTBlobManager? {
        guard let blobManager: RCTBlobManager = ReactAppProvider.getModule(type: RCTBlobManager.self) else {
            NSLog("NativeFsModule: Failed to get RCTBlobManager")
            return nil
        }
        return blobManager
    }
    
    private func readBlobRefAsData(_ blob: [String: Any]) -> Data? {
        guard let data = getBlobManager()?.resolve(blob) else {
            NSLog("NativeFsModule: Failed to resolve blob")
            return nil
        }
        return data
    }
    
    private func readDataAsBlobRef(_ data: Data) -> [String: Any]? {
        guard let blobId = getBlobManager()?.store(data) else {
            NSLog("NativeFsModule: Failed to store data as blob")
            return nil
        }
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
    
    static func readJson(_ filePath: String) throws -> [String: Any]? {
        guard let data = readData(filePath) else {
            return nil
        }
        let result = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        return result as? [String: Any]
    }
    
    static func save(_ data: Data, filepath: String) throws {
        let directoryURL = URL(fileURLWithPath: (filepath as NSString).deletingLastPathComponent)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        let options: Data.WritingOptions = encryptionEnabled ? [.atomic, .completeFileProtection] : .atomic
        try data.write(to: URL(fileURLWithPath: filepath), options: options)
    }
    
    static func move(_ filepath: String, newPath: String) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: filepath) else {
            throw NSError(domain: NativeFsErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "File does not exist"])
        }
        let directoryURL = URL(fileURLWithPath: (newPath as NSString).deletingLastPathComponent)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        try fileManager.moveItem(atPath: filepath, toPath: newPath)
    }
    
    static func remove(_ filepath: String) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: filepath) else {
            NSLog("Trying to delete non-existing file: \(filepath)")
            return
        }
        try fileManager.removeItem(atPath: filepath)
    }
    
    static func ensureWhiteListedPath(_ paths: [String]) throws {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
        let tempPath = (NSTemporaryDirectory() as NSString).standardizingPath
        
        for path in paths {
            if !path.hasPrefix(documentsPath) &&
                !path.hasPrefix(cachesPath) &&
                !path.hasPrefix(tempPath) {
                throw NSError(
                    domain: NativeFsErrorDomain,
                    code: 999,
                    userInfo: [NSLocalizedDescriptionKey: "The path \(path) does not point to the documents directory"]
                )
            }
        }
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
        
        guard isWhiteListedPath(filepath, reject: reject) else { return }
        
        guard let data = readBlobRefAsData(blob) else {
            reject(NativeFsModule.ERROR_READ_FAILED, NativeFsModule.formatError("Failed to read blob"), nil)
            return
        }
        
        do {
            try NativeFsModule.save(data, filepath: filepath)
            resolve(nil)
        } catch {
            reject(NativeFsModule.ERROR_SAVE_FAILED, NativeFsModule.formatError("Save failed"), error)
        }
    }
    
    public func read(_ filepath: String,
                     resolve: @escaping RCTPromiseResolveBlock,
                     reject: @escaping RCTPromiseRejectBlock) {
        
        guard isWhiteListedPath(filepath, reject: reject) else { return }
        
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
        
        guard isWhiteListedPath(filepath, newPath, reject: reject) else { return }
        
        do {
            try NativeFsModule.move(filepath, newPath: newPath)
            resolve(nil)
        } catch {
            reject(NativeFsModule.ERROR_MOVE_FAILED, NativeFsModule.formatError("Failed to move file"), error)
        }
    }
    
    public func remove(_ filepath: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        
        guard isWhiteListedPath(filepath, reject: reject) else { return }
        
        do {
            try NativeFsModule.remove(filepath)
            resolve(nil)
        } catch {
            reject(NativeFsModule.ERROR_DELETE_FAILED, NativeFsModule.formatError("Failed to delete file"), error)
        }
    }
    
    public func list(_ dirPath: String,
                     resolve: @escaping RCTPromiseResolveBlock,
                     reject: @escaping RCTPromiseRejectBlock) {
        
        guard isWhiteListedPath(dirPath, reject: reject) else { return }
        
        resolve(NativeFsModule.list(dirPath))
    }
    
    public func readAsDataURL(_ filePath: String,
                              resolve: @escaping RCTPromiseResolveBlock,
                              reject: @escaping RCTPromiseRejectBlock) {
        
        guard isWhiteListedPath(filePath, reject: reject) else { return }
        
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
        guard isWhiteListedPath(filepath, reject: reject) else { return }
        
        let exists = FileManager.default.fileExists(atPath: filepath)
        resolve(NSNumber(value: exists))
    }
    
    public func readJson(_ filepath: String,
                         resolve: @escaping RCTPromiseResolveBlock,
                         reject: @escaping RCTPromiseRejectBlock) {
        
        guard isWhiteListedPath(filepath, reject: reject) else { return }
        
        do {
            let data = try NativeFsModule.readJson(filepath)
            resolve(data)
        } catch {
            reject(NativeFsModule.ERROR_SERIALIZATION_FAILED, NativeFsModule.formatError("Failed to deserialize JSON"), error)
        }
    }
    
    public func writeJson(_ data: [String: Any],
                          filepath: String,
                          resolve: @escaping RCTPromiseResolveBlock,
                          reject: @escaping RCTPromiseRejectBlock) {
        
        guard isWhiteListedPath(filepath, reject: reject) else { return }
        
        var jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        } catch {
            reject(NativeFsModule.ERROR_SERIALIZATION_FAILED, NativeFsModule.formatError("Failed to serialize JSON"), error)
            return
        }
        
        do {
            try NativeFsModule.save(jsonData, filepath: filepath)
            resolve(nil)
        } catch {
            reject(NativeFsModule.ERROR_SAVE_FAILED, NativeFsModule.formatError("Failed to write JSON"), error)
        }
    }
    
    public let constants: NSDictionary = [
        "DocumentDirectoryPath": NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "",
        "SUPPORTS_DIRECTORY_MOVE": true,
        "SUPPORTS_ENCRYPTION": true
    ]
    
    private func isWhiteListedPath(_ paths: String..., reject: RCTPromiseRejectBlock) -> Bool {
        do {
            try NativeFsModule.ensureWhiteListedPath(paths)
            return true
        } catch let error {
            reject(NativeFsModule.INVALID_PATH, NativeFsModule.formatError("Path not accessible"), error)
            return false
        }
    }
}

