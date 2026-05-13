import Foundation
import React

public class DevHelper {
    public static func setDebugMode(enabled: Bool) {
        AppPreferences.remoteDebuggingEnabled = enabled
    }
    
    public static func setShakeToShowDevMenuEnabled(enabled: Bool) {
        ReactHostHelper().emitEvent("mendixSetShakeToShowDevMenu", payload: enabled)
    }
}
