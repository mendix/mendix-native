import Foundation

public class BundleHelper {
    public static func getJSBundleFile() -> URL? {
        if hasNativeOtaBundle(), let bundleUrl = OtaJSBundleFileProvider.getBundleUrl() {
            return bundleUrl
        }
        return Bundle.main.url(forResource: "index.ios", withExtension: "bundle", subdirectory: "Bundle")
    }
    
    public static func hasNativeOtaBundle() -> Bool {
        return FileManager.default.contents(atPath: OtaHelpers.getOtaManifestFilepath()) != nil
    }
}
