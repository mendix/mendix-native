import React

public class DevHelper {
    
    public static func showAppMenu() {
        devMenu?.show()
    }
    
    public static func toggleElementInspector() {
        devSettings?.toggleElementInspector()
    }
    
    public static var devSettings: RCTDevSettings? {
        return ReactHostManager.module(type: RCTDevSettings.self)
    }
    
    public static var devMenu: RCTDevMenu? {
        return ReactHostManager.module(type: RCTDevMenu.self)
    }
    
    public static func setDebugMode(enabled: Bool) {
        AppPreferences.remoteDebuggingEnabled = enabled
        devSettings?.isDebuggingRemotely = enabled
    }
}
