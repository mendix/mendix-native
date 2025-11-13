import Foundation

public class OtaJSBundleFileProvider: NSObject {
    
    static func formatMessage(_ message: String) -> String {
        return "\(String(describing: OtaJSBundleFileProvider.self)): \(message)"
    }
}

extension OtaJSBundleFileProvider: JSBundleFileProviderProtocol {
    /*
     * Returns the OTA bundle's location URL if an OTA bundle has been downloaded and deployed.
     * It:
     *   - Reads the OTA manifest.json
     *     - Verifies current app version matches the OTA's deployed app version
     *     - Verifies a bundle exists in the location expected
     *   - Returns the absolute path to the OTA bundle if it succeeds
     */
    public static func getBundleUrl() -> URL? {
        let manifestPath = OtaHelpers.getOtaManifestFilepath()
        
        guard FileManager.default.fileExists(atPath: manifestPath) else {
            return nil
        }
        
        guard let manifest = OtaHelpers.readManifestAsDictionary() else {
            NSLog("No OTA available.")
            return nil
        }
        
        // If the app version does not match the manifest version we assume the app has been updated/downgraded
        // In this case do not use the OTA bundle.
        let currentVersion = OtaHelpers.resolveAppVersion()
        guard let manifestVersion = manifest[MANIFEST_APP_VERSION_KEY] as? String,
              currentVersion == manifestVersion else {
            
            if let manifestVersionString = manifest[MANIFEST_APP_VERSION_KEY] as? String {
                NSLog("Manifest version: %@", manifestVersionString)
            }
            NSLog("Current version: %@", currentVersion)
            NSLog("New app version discovered. Loading default bundle.")
            return nil
        }
        
        guard let relativeBundlePath = manifest[MANIFEST_RELATIVE_BUNDLE_PATH_KEY] as? String else {
            NSLog("OTA bundle does not exist.")
            return nil
        }
        
        let bundlePath = OtaHelpers.resolveAbsolutePathRelativeToOtaDir("/\(relativeBundlePath)")
        
        guard FileManager.default.fileExists(atPath: bundlePath) else {
            NSLog("OTA bundle does not exist.")
            return nil
        }
        
        guard let encodedPath = bundlePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        return URL(string: encodedPath)
    }
}
