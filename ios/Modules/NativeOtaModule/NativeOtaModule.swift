import Foundation
import React
import SSZipArchive

@objcMembers
public class NativeOtaModule: NSObject {
    
    public override init() {
        super.init()
        Self.initializeOtaDirectory()
    }
    
    public static func resolveAppVersion() -> String {
        return OtaHelpers.resolveAppVersion()
    }
    
    private static func initializeOtaDirectory() {
        let fileManager = FileManager.default
        let otaDir = OtaHelpers.getOtaDir()
        
        do {
            try fileManager.createDirectory(atPath: otaDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            NSLog("Failed to create OTA directory: %@", error.localizedDescription)
        }
    }
    
    /**
     * Accepts a structure of:
     * {
     *    url: string, // url to download from
     * }
     *
     * Returns a structure of:
     * {
     *    otaPackage: string // zip file name
     * }
     */
    public func download(_ config: [String: Any], promise: Promise) {
        
        let otaDir = OtaHelpers.getOtaDir()
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: otaDir) {
            do {
                try fileManager.createDirectory(atPath: otaDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                promise.reject(OTA_DOWNLOAD_FAILED, "Failed creating ota directories", error)
                return
            }
        }
        
        guard let url = config[DOWNLOAD_CONFIG_URL_KEY] as? String else {
            promise.reject(INVALID_DOWNLOAD_CONFIG, "Key url is invalid.", nil)
            return
        }
        
        guard let runtimeUrl = MxConfiguration.runtimeUrl?.absoluteString else {
            promise.reject(INVALID_RUNTIME_URL, "Runtime URL is not set.", nil)
            return
        }
        
        let isRuntimeUrl = url.hasPrefix(runtimeUrl)
        if !isRuntimeUrl {
            promise.reject(INVALID_RUNTIME_URL, "Invalid OTA URL.", nil)
            return
        }
        
        let zipFilename = generateZipFilename()
        let downloadPath = OtaHelpers.resolveAbsolutePathRelativeToOtaDir("/\(zipFilename)")
        
        let downloadHandler = NativeDownloadHandler(
            [:],
            doneCallback: {
                promise.resolve(["otaPackage": zipFilename])
            },
            progressCallback: nil,
            failCallback: { error in
                promise.reject(OTA_DOWNLOAD_FAILED, "OTA download failed.", error)
            }
        )
        
        downloadHandler.download(url, downloadPath: downloadPath)
    }
    
    /**
     * Accepts a structure:
     * {
     *    otaDeploymentID: string, // current ota deployment id
     *    otaPackage: string, // the zip filename to unzip
     *    extractionDir: string, // the relative path to extract the bundle to
     * }
     *
     * Generates a manifest.json:
     * {
     *   otaDeploymentID: string, // current ota deployment id
     *   relativeBundlePath: string, // relative path to the index.*.bundle
     *   appVersion: string //  version number + code at installation time
     * }
     */
    
    public func deploy(_ config: [String: Any], promise: Promise) {
        
        guard let otaDeploymentID = config[MANIFEST_OTA_DEPLOYMENT_ID_KEY] as? String else {
            promise.reject(INVALID_DOWNLOAD_CONFIG, "Key otaDeploymentID is invalid.", nil)
            return
        }
        
        guard let zipFile = config[DEPLOY_CONFIG_OTA_PACKAGE_KEY] as? String else {
            promise.reject(INVALID_DOWNLOAD_CONFIG, "Key otaPackage is invalid.", nil)
            return
        }
        
        guard let extractionDir = config[DEPLOY_CONFIG_EXTRACTION_DIR] as? String else {
            promise.reject(INVALID_DOWNLOAD_CONFIG, "Key extractionDir is invalid.", nil)
            return
        }
        
        let zipPath = OtaHelpers.resolveAbsolutePathRelativeToOtaDir("/\(zipFile)")
        let unzipDir = OtaHelpers.resolveAbsolutePathRelativeToOtaDir("/\(extractionDir)")
        
        let oldManifest = OtaHelpers.readManifestAsDictionary()
        
        let fileExists = FileManager.default.fileExists(atPath: zipPath)
        if !fileExists {
            let errorMessage = "[OTA] OTA package does not exist."
            NSLog("%@", errorMessage)
            promise.reject(OTA_ZIP_FILE_MISSING, errorMessage, nil)
            return
        }
        
        let extractionDirExists = FileManager.default.fileExists(atPath: unzipDir)
        if extractionDirExists {
            NSLog("[OTA] Extraction directory exists. Removing it.")
            removeOldBundle(unzipDir)
        }
        
        let unzipped = SSZipArchive.unzipFile(atPath: zipPath, toDestination: unzipDir, overwrite: false, password: nil, progressHandler: nil)
        if !unzipped {
            NSLog("[OTA] Unzipping OTA failed")
            removeZipFile(unzipDir)
            promise.reject(OTA_DEPLOYMENT_FAILED, "OTA deployment failed.", nil)
            return
        }
        
        let manifestDict: [String: Any] = [
            MANIFEST_OTA_DEPLOYMENT_ID_KEY: otaDeploymentID,
            MANIFEST_RELATIVE_BUNDLE_PATH_KEY: "\(extractionDir)/index.ios.bundle",
            MANIFEST_APP_VERSION_KEY: NativeOtaModule.resolveAppVersion()
        ]
        
        do {
            let manifestData = try JSONSerialization.data(withJSONObject: manifestDict, options: .prettyPrinted)
            let manifestPath = OtaHelpers.resolveAbsolutePathRelativeToOtaDir("/\(MANIFEST_FILE_NAME)")
            
            try manifestData.write(to: URL(fileURLWithPath: manifestPath), options: .atomic)
        } catch {
            NSLog("[OTA] Manifest serialization or writing failed")
            try? FileManager.default.removeItem(atPath: unzipDir)
            promise.reject(OTA_DEPLOYMENT_FAILED, "Writing OTA manifest failed.", error)
            return
        }
        
        // Old bundle cleanup
        let shouldRemoveOldBundle = oldManifest != nil &&
        otaDeploymentID != (oldManifest?[MANIFEST_OTA_DEPLOYMENT_ID_KEY] as? String)
        
        if shouldRemoveOldBundle,
           let oldManifest = oldManifest,
           let relativeBundlePath = oldManifest[MANIFEST_RELATIVE_BUNDLE_PATH_KEY] as? String {
            let oldBundleDir = OtaHelpers.resolveAbsolutePathRelativeToOtaDir("/\((relativeBundlePath as NSString).deletingLastPathComponent)")
            removeOldBundle(oldBundleDir)
        }
        
        removeZipFile(zipPath)
        
        NSLog("[OTA] OTA deployed.")
        promise.resolve(nil)
    }
    
    // MARK: - Private Methods
    
    private func generateZipFilename() -> String {
        return "\(UUID().uuidString).zip"
    }
    
    @discardableResult
    private func removeZipFile(_ zipPath: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: zipPath)
            return true
        } catch {
            NSLog("[OTA] Error: %@", error.localizedDescription)
            return false
        }
    }
    
    @discardableResult
    private func removeOldBundle(_ bundleDir: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: bundleDir)
            return true
        } catch {
            NSLog("[OTA] Error: %@", error.localizedDescription)
            return false
        }
    }
}
