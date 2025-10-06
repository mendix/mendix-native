import Foundation
import RNCAsyncStorage

class StorageHelper {
    
    static func clearAll() {
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

    static func clearDataAt(url: URL, component: String) {
        let path = url.appendingPathComponent(component).path
        _ = NativeFsModule.remove(path, error: nil)
    }
}
