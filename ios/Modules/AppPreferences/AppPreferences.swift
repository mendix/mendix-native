import Foundation

public class AppPreferences: NSObject {
    @UserDefault(key: "ApplicationUrl", defaultValue: nil)
    static var _appUrl: String?
    
    @UserDefault(key: "DevModeEnabled", defaultValue: false)
    static var _devModeEnabled: Bool
    
    @UserDefault(key: "RemoteDebuggingEnabled", defaultValue: false)
    static var _remoteDebuggingEnabled: Bool
    
    @UserDefault(key: "showInspector", defaultValue: false)
    static var _elementInspectorEnabled: Bool
    
    @UserDefault(key: "RemoteDebuggingPackagerPort", defaultValue: AppUrl.defaultPackagerPort)
    private static var _packagerPort: Int
    
    public static var remoteDebuggingPackagerPort: Int {
        get { AppUrl.ensurePort(_packagerPort) }
        set { _packagerPort = newValue }
    }
    
    public static var appUrl: String? {
        get { _appUrl }
        set { _appUrl = newValue }
    }
    
    public static var devModeEnabled: Bool {
        get { _devModeEnabled }
        set { _devModeEnabled = newValue }
    }
    
    public static var remoteDebuggingEnabled: Bool {
        get { _remoteDebuggingEnabled }
        set { _remoteDebuggingEnabled = newValue }
    }
    
    public static var elementInspectorEnabled: Bool {
        get { _elementInspectorEnabled }
        set { _elementInspectorEnabled = newValue }
    }
    
    public static var safeAppUrl: String {
        return appUrl ?? ""
    }
    
}
