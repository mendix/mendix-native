import Foundation

@objcMembers
public class MxConfiguration: NSObject {
    
    /**
     * Side note for 11: I've bumped the nativeBinaryVersion from 12 to 30,
     * because there needs to be version increment space for Mx 10.24.
     * You can remove this comment when the next version is released.
     *
     * Increment nativeBinaryVersion to 30 for OP-SQlite database migration
     */
    private static let nativeBinaryVersion: Int = 30
    private static let defaultDatabaseName = "default"
    private static let defaultFilesDirectoryName = "files/default"
    
    private static var _runtimeUrl: URL?
    private static var _appName: String?
    private static var _databaseName: String?
    private static var _filesDirectoryName: String?
    private static var _warningsFilter: WarningsFilter = .all
    private static var _isDeveloperApp: Bool = false
    private static var _appSessionId: String?
    
    // MARK: - Static Getters and Setters
    
    static var runtimeUrl: URL? {
        get { return _runtimeUrl }
        set { _runtimeUrl = newValue }
    }
    
    static var appName: String? {
        get { return _appName }
        set { _appName = newValue }
    }
    
    static var appSessionId: String? {
        get { return _appSessionId }
        set { _appSessionId = newValue }
    }
    
    static var isDeveloperApp: Bool {
        get { return _isDeveloperApp }
        set { _isDeveloperApp = newValue }
    }
    
    static var databaseName: String {
        get { return _databaseName ?? defaultDatabaseName }
        set { _databaseName = newValue }
    }
    
    static var filesDirectoryName: String {
        get { return _filesDirectoryName ?? defaultFilesDirectoryName }
        set { _filesDirectoryName = newValue }
    }
    
    static var warningsFilter: WarningsFilter {
        get { return _warningsFilter }
        set { _warningsFilter = newValue }
    }
    
    public func constants() -> [String: Any] {
        guard let runtimeUrl = MxConfiguration.runtimeUrl else {
            let exception = NSException(
                name: NSExceptionName("RUNTIME_URL_MISSING"),
                reason: "Runtime URL was not set prior to launch.",
                userInfo: nil
            )
            exception.raise()
            return [:]
        }
        
        return [
            "RUNTIME_URL": runtimeUrl.absoluteString,
            "APP_NAME": MxConfiguration.appName ?? NSNull(),
            "DATABASE_NAME": MxConfiguration.databaseName,
            "FILES_DIRECTORY_NAME": MxConfiguration.filesDirectoryName,
            "WARNINGS_FILTER_LEVEL": MxConfiguration.warningsFilter.stringValue,
            "OTA_MANIFEST_PATH": OtaHelpers.getOtaManifestFilepath(),
            "IS_DEVELOPER_APP": NSNumber(value: MxConfiguration.isDeveloperApp),
            "NATIVE_DEPENDENCIES": OtaHelpers.getNativeDependencies(),
            "NATIVE_BINARY_VERSION": NSNumber(value: MxConfiguration.nativeBinaryVersion),
            "APP_SESSION_ID": MxConfiguration.appSessionId ?? NSNull()
        ]
    }
    
    public static func update(from mendixApp: MendixApp) {
        MxConfiguration.runtimeUrl = mendixApp.runtimeUrl
        MxConfiguration.appName = mendixApp.identifier
        MxConfiguration.isDeveloperApp = mendixApp.isDeveloperApp
        
        if let identifier = mendixApp.identifier {
            MxConfiguration.databaseName = identifier
            MxConfiguration.filesDirectoryName = "files/\(identifier)"
        }
        
        MxConfiguration.warningsFilter = mendixApp.warningsFilter
        
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000.0)
        let randomValue = arc4random_uniform(1000)
        MxConfiguration.appSessionId = "\(randomValue)\(timestamp)"
    }
}

//Checked
