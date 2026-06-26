import Foundation
import React

public class DevHelper {
    public static func setDebugMode(enabled: Bool) {
        AppPreferences.remoteDebuggingEnabled = enabled
    }
    
    public static func setShakeToShowDevMenuEnabled(enabled: Bool) {
        getModule(type: RCTDevSettings.self)?.isShakeToShowDevMenuEnabled = enabled
        
        // This event can be triggered to facilitate communication with the DevSettings JS module. Please refer to dev-settings.ts for further details.
        // getModule(type: RCTEventEmitter.self)?.sendEvent(withName: "mendixSetShakeToShowDevMenu", body: enabled)
    }
    
    public static func hideDevLoadingView() {
        getModule(type: RCTDevLoadingView.self)?.hide()
    }
    
    public static func getModule<T: NSObject>(type: T.Type) -> T? {
        return ReactAppProvider.shared()?.reactHost()?.moduleRegistry.module(for: type.self) as? T
    }
}
