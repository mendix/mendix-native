import Foundation
import RNCAsyncStorage

public class StorageHelper {
    
    public static func clearAll() {
        if let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            clearDataAt(url: documentPath, component: MxConfiguration.filesDirectoryName)
        }
        
        RNCAsyncStorage.clearAllData()
        KeychainHelper.clear(scopeKey: MxConfiguration.appName)
        NativeCookieModule.clearAll()
        
        if let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first {
            clearDataAt(url: libraryPath, component: "LocalDatabase/\(MxConfiguration.databaseName)")
        }
    }

    public static func clearDataAt(url: URL, component: String) {
        let path = url.appendingPathComponent(component).path
        do {
            try NativeFsModule.remove(path)
        } catch {
            NSLog("Failed to clear data at path: \(path), error: \(error.localizedDescription)")
        }
    }
}
