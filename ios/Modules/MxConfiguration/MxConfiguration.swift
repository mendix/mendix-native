import Foundation

public struct MxConfiguration {
    
    static let nativeBinaryVersion: Int = 32
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
