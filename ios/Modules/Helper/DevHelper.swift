import Foundation
import React

public class DevHelper {
    public static func setDebugMode(enabled: Bool) {
        AppPreferences.remoteDebuggingEnabled = enabled
    }
    
    @MainActor
    public static func setShakeToShowDevMenuEnabled(enabled: Bool) {
        getModule(type: RCTDevSettings.self)?.isShakeToShowDevMenuEnabled = enabled
    }
    
    @MainActor
    public static func hideDevLoadingView() {
        getModule(type: RCTDevLoadingView.self)?.hide()
    }
    
    // Private so only main-thread callers in this file can use it. TurboModules must use their injected moduleRegistry.
    @MainActor
    private static func getModule<T: NSObject>(type: T.Type) -> T? {
        return ReactHostHelper.module(for: T.self) as? T
    }
}
