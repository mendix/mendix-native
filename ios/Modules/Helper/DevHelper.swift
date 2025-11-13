import React

public class DevHelper {
    
    public static func showAppMenu() {
        devMenu?.show()
    }
    
    public static func toggleElementInspector() {
        devSettings?.toggleElementInspector()
    }
    
    public static var devSettings: RCTDevSettings? {
        return ReactAppProvider.getModule(type: RCTDevSettings.self)
    }
    
    public static var devMenu: RCTDevMenu? {
        return ReactAppProvider.getModule(type: RCTDevMenu.self)
    }
    
    public static func setDebugMode(enabled: Bool) {
        AppPreferences.remoteDebuggingEnabled = enabled
        devSettings?.isDebuggingRemotely = enabled
    }
    
    public static func hideDevLoadingView() {
        devLoadingView?.hide()
    }
    
    public static var devLoadingView: RCTDevLoadingView? {
        return ReactAppProvider.getModule(type: RCTDevLoadingView.self)
    }
}
