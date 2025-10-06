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
        get {
            return AppUrl.ensurePort(_packagerPort)
        }
        set {
            _packagerPort = newValue
        }
    }
    
    public static var appUrl = _appUrl
    public static var devModeEnabled = _devModeEnabled
    public static var remoteDebuggingEnabled = _remoteDebuggingEnabled
    public static var elementInspectorEnabled = _elementInspectorEnabled
    
    public static var safeAppUrl: String {
        return appUrl ?? ""
    }
    
}
//Checked
