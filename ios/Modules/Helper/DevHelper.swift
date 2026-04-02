import Foundation
import React

public class DevHelper {

    public static func showAppMenu() {
        devMenu?.show()
    }

    public static func toggleElementInspector() {
        devSettings?.toggleElementInspector()
    }

    // Modern Architecture: Access dev modules through ReactAppProvider's moduleRegistry
    // Works with RN 0.83+ where RCTBridge.current() returns nil
    public static var devSettings: RCTDevSettings? {
        return ReactAppProvider.getModule(type: RCTDevSettings.self)
    }

    public static var devMenu: RCTDevMenu? {
        return ReactAppProvider.getModule(type: RCTDevMenu.self)
    }

    public static func setDebugMode(enabled: Bool) {
        AppPreferences.remoteDebuggingEnabled = enabled

        // Modern Architecture (RN 0.83+):
        // Debug operations are controlled from JavaScript via the DevSettings TurboModule.
        // Native code no longer needs to control debugging - it's all JavaScript-driven.
        //
        // To open the debugger from JavaScript:
        //   import { DevSettings } from 'mendix-native';
        //   DevSettings.openDebugger();
        //
        // This method now only stores the preference. Actual debug control is via JavaScript.
    }

    public static func hideDevLoadingView() {
        devLoadingView?.hide()
    }

    public static var devLoadingView: RCTDevLoadingView? {
        return ReactAppProvider.getModule(type: RCTDevLoadingView.self)
    }
}
