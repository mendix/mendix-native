import Foundation
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

        // RN <= 0.82 exposed isDebuggingRemotely on RCTDevSettings.
        // RN 0.83+ removed that toggle and moved to on-device debugging tooling.
        if let devSettings,
           devSettings.responds(to: NSSelectorFromString("setIsDebuggingRemotely:")) {
            devSettings.setValue(enabled, forKey: "isDebuggingRemotely")
            return
        }

        if enabled {
            openDebuggerIfAvailable()
        } else {
            disableDebuggerIfAvailable()
        }
    }

    private static func openDebuggerIfAvailable() {
        guard let bundleURL = ReactNative.shared.bundleURL(),
              let inspectorHelperClass = NSClassFromString("RCTInspectorDevServerHelper") as? NSObject.Type else {
            return
        }

        let selector = NSSelectorFromString("openDebugger:withErrorMessage:")
        if inspectorHelperClass.responds(to: selector) {
            _ = inspectorHelperClass.perform(
                selector,
                with: bundleURL,
                with: "Failed to open debugger. Please check that the dev server is running and reload the app."
            )
        }
    }

    private static func disableDebuggerIfAvailable() {
        guard let inspectorHelperClass = NSClassFromString("RCTInspectorDevServerHelper") as? NSObject.Type else {
            return
        }

        let selector = NSSelectorFromString("disableDebugger")
        if inspectorHelperClass.responds(to: selector) {
            _ = inspectorHelperClass.perform(selector)
        }
    }
    
    public static func hideDevLoadingView() {
        devLoadingView?.hide()
    }
    
    public static var devLoadingView: RCTDevLoadingView? {
        return ReactAppProvider.getModule(type: RCTDevLoadingView.self)
    }
}
