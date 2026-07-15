import Foundation
import React
import SSZipArchive


@objcMembers
public class OtaDeploymentConfiguration: NSObject {
    let otaDeploymentID: String?
    let otaPackage: String?
    let extractionDir: String?
    
    public init(otaDeploymentID: String?, otaPackage: String?, extractionDir: String?) {
        self.otaDeploymentID = otaDeploymentID
        self.otaPackage = otaPackage
        self.extractionDir = extractionDir
    }
}

@objcMembers
public class OtaDownloadConfiguration: NSObject {
    let url: String?
    
    public init(url: String?) {
        self.url = url
    }
}

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
    public func download(_ config: OtaDownloadConfiguration, promise: Promise) {
        
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
        
        guard let url = config.url else {
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
            connectionTimeout: nil,
            mimeType: nil,
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
    
    public func deploy(_ config: OtaDeploymentConfiguration, promise: Promise) {
        
        guard let otaDeploymentID = config.otaDeploymentID else {
            promise.reject(INVALID_DOWNLOAD_CONFIG, "Key otaDeploymentID is invalid.", nil)
            return
        }
        
        guard let zipFile = config.otaPackage else {
            promise.reject(INVALID_DOWNLOAD_CONFIG, "Key otaPackage is invalid.", nil)
            return
        }
        
        guard let extractionDir = config.extractionDir else {
            promise.reject(INVALID_DOWNLOAD_CONFIG, "Key extractionDir is invalid.", nil)
            return
        }
        
        let zipPath = OtaHelpers.resolveAbsolutePathRelativeToOtaDir("/\(zipFile)")
        let unzipDir = OtaHelpers.resolveAbsolutePathRelativeToOtaDir("/\(extractionDir)")
        
        let oldManifest = OtaHelpers.readManifestAsDictionary()
        
        // Loop protection: refuse to redeploy a deployment that is already the active one.
        // Redeploying and reloading into an already-active deployment restarts the app into
        // the same bundle, causing an infinite download -> deploy -> reload loop. This happens
        // when the served OTA bundle's embedded deploymentID never matches the server-advertised
        // deploymentID (e.g. a bundle served as an OTA update but built for a different deployment).
        // Rejecting here makes the JS OTA flow skip the reload, so the app keeps running the
        // currently deployed bundle instead of looping.
        if let oldManifest = oldManifest,
           let deployedID = oldManifest[MANIFEST_OTA_DEPLOYMENT_ID_KEY] as? String,
           deployedID == otaDeploymentID,
           let deployedBundlePath = oldManifest[MANIFEST_RELATIVE_BUNDLE_PATH_KEY] as? String,
           FileManager.default.fileExists(atPath: OtaHelpers.resolveAbsolutePathRelativeToOtaDir("/\(deployedBundlePath)")) {
            let message = "[OTA] Deployment \(otaDeploymentID) is already active. Skipping redeploy to prevent a reload loop."
            NSLog("%@", message)
            removeZipFile(zipPath)
            promise.reject(OTA_ALREADY_DEPLOYED, message, nil)
            return
        }
        
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
            // Diagnostic: the "OTA package" is not a valid zip. This most often means the
            // server returned a non-zip response (e.g. an HTML/JSON error body) that was
            // saved as the download. Log the size and leading bytes so the real cause is visible.
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: zipPath)[.size] as? Int) ?? nil
            var preview = ""
            if let handle = FileManager.default.contents(atPath: zipPath) {
                preview = String(data: handle.prefix(64), encoding: .utf8) ?? handle.prefix(4).map { String(format: "%02x", $0) }.joined()
            }
            NSLog("[OTA] Unzipping OTA failed. Downloaded file size: \(fileSize ?? -1) bytes. Leading bytes: \(preview)")
            removeZipFile(zipPath)
            promise.reject(OTA_DEPLOYMENT_FAILED, "OTA deployment failed: downloaded package is not a valid zip.", nil)
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
