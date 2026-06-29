import Foundation

@objcMembers
public class MxConfigProxy: NSObject {
    public var runtimeUrl: String
    public var appName: String?
    public var databaseName: String
    public var filesDirectoryName: String
    public var warningsFilter: String
    public var otaManifestPath: String
    public var isDeveloperApp: NSNumber
    public var nativeDependencies: [String: Any]
    public var nativeBinaryVersion: NSNumber
    public var appSessionId: String?
    
    init(runtimeUrl: String, appName: String?, databaseName: String, filesDirectoryName: String, warningsFilter: String, otaManifestPath: String, isDeveloperApp: NSNumber, nativeDependencies: [String : Any], nativeBinaryVersion: NSNumber, appSessionId: String?) {
        self.runtimeUrl = runtimeUrl
        self.appName = appName
        self.databaseName = databaseName
        self.filesDirectoryName = filesDirectoryName
        self.warningsFilter = warningsFilter
        self.otaManifestPath = otaManifestPath
        self.isDeveloperApp = isDeveloperApp
        self.nativeDependencies = nativeDependencies
        self.nativeBinaryVersion = nativeBinaryVersion
        self.appSessionId = appSessionId
    }
    
    
    public static func prepare() -> MxConfigProxy? {
        guard let runtimeUrl = MxConfiguration.runtimeUrl?.absoluteString else {
            let exception = NSException(
                name: NSExceptionName("RUNTIME_URL_MISSING"),
                reason: "Runtime URL was not set prior to launch.",
                userInfo: nil
            )
            exception.raise()
            return nil
        }
        
        return MxConfigProxy(
            runtimeUrl: runtimeUrl,
            appName: MxConfiguration.appName,
            databaseName: MxConfiguration.databaseName,
            filesDirectoryName: MxConfiguration.filesDirectoryName,
            warningsFilter: MxConfiguration.warningsFilter.stringValue,
            otaManifestPath: OtaHelpers.getOtaManifestFilepath(),
            isDeveloperApp: NSNumber(booleanLiteral: MxConfiguration.isDeveloperApp),
            nativeDependencies: OtaHelpers.getNativeDependencies(),
            nativeBinaryVersion: NSNumber(integerLiteral: MxConfiguration.nativeBinaryVersion),
            appSessionId: MxConfiguration.appSessionId
        )
    }
}
