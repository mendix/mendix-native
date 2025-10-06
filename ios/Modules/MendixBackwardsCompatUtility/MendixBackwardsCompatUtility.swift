import Foundation

public class MendixBackwardsCompatUtility: NSObject {
    
    private static let versionDictionary: [String: UnsupportedFeatures] = [
        "8.9": UnsupportedFeatures(reloadInClient: true, hideSplashScreenInClient: true),
        "8.10": UnsupportedFeatures(reloadInClient: false, hideSplashScreenInClient: true),
        "8.11": UnsupportedFeatures(reloadInClient: false, hideSplashScreenInClient: true),
        "8.12.0": UnsupportedFeatures(reloadInClient: false, hideSplashScreenInClient: true),
        "DEFAULT": UnsupportedFeatures(reloadInClient: false, hideSplashScreenInClient: false)
    ]
    
    private static var _unsupportedFeatures: UnsupportedFeatures? = versionDictionary["DEFAULT"]
    private static let lock = NSLock()
    
    public static func unsupportedFeatures() -> UnsupportedFeatures? {
        lock.lock()
        defer { lock.unlock() }
        return _unsupportedFeatures
    }
    
    public static func update(_ forVersion: String) {
        let versionParts = forVersion.components(separatedBy: ".")
        let versionDict = versionDictionary
        
        lock.lock()
        defer { lock.unlock() }
        
        // Try with up to 3 parts (major.minor.patch)
        if versionParts.count >= 3 {
            let threePartVersion = Array(versionParts.prefix(3)).joined(separator: ".")
            if let features = versionDict[threePartVersion] {
                _unsupportedFeatures = features
                return
            }
        }
        
        // Try with 2 parts (major.minor)
        if versionParts.count >= 2 {
            let twoPartVersion = Array(versionParts.prefix(2)).joined(separator: ".")
            if let features = versionDict[twoPartVersion] {
                _unsupportedFeatures = features
                return
            }
        }
        
        // Try with 1 part (major)
        if versionParts.count >= 1 {
            if let features = versionDict[versionParts[0]] {
                _unsupportedFeatures = features
                return
            }
        }
        
        // Default fallback
        _unsupportedFeatures = versionDict["DEFAULT"]
    }
    
    static func isHideSplashScreenInClientSupported() -> Bool {
        
        if let unsupportedFeatures = Self.unsupportedFeatures() {
            return !unsupportedFeatures.hideSplashScreenInClient
        }
        
        return true
    }
}

//Checked
