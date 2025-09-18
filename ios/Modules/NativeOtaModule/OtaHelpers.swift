import Foundation

class OtaHelpers: NSObject {
    
    private static func version() -> String {
        let info = Bundle.main.infoDictionary
        return info?["CFBundleVersion"] as? String ?? ""
    }
    
    private static func shortVersion() -> String {
        let info = Bundle.main.infoDictionary
        return info?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    private static func identifier() -> String {
        let info = Bundle.main.infoDictionary
        return info?["CFBundleIdentifier"] as? String ?? ""
    }
    
    static func resolveAppVersion() -> String {
        return "\(shortVersion())-\(version())"
    }
    
    static func getOtaDir() -> String {
        let supportDirectory = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first ?? ""
        return "\(supportDirectory)/\(identifier())/\(OTA_DIR_NAME)"
    }
    
    static func getOtaManifestFilepath() -> String {
        return resolveAbsolutePathRelativeToOtaDir("/\(MANIFEST_FILE_NAME)")
    }
    
    static func resolveAbsolutePathRelativeToOtaDir(_ path: String) -> String {
        return "\(getOtaDir())\(path)"
    }
    
    static func readManifestAsDictionary() -> [String: Any]? {
        let manifestPath = getOtaManifestFilepath()
        
        guard let contents = NSData(contentsOfFile: manifestPath) else {
            return nil
        }
        
        do {
            let jsonOutput = try JSONSerialization.jsonObject(with: contents as Data, options: [])
            return jsonOutput as? [String: Any]
        } catch {
            return nil
        }
    }
    
    static func getNativeDependencies() -> [String: Any] {
        guard let path = Bundle.main.path(forResource: "native_dependencies", ofType: "json") else {
            return [:]
        }
        
        return NativeFsModule.readJson(path, error: nil) ?? [:]
    }
}

//Checked
