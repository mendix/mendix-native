package com.mendix.mendixnative.react

import com.facebook.react.ReactInstanceManager
import com.facebook.react.bridge.ReactContext
import com.facebook.react.modules.core.DeviceEventManagerModule

@CopiedFrom(ReactInstanceManager::class)
fun toggleElementInspector(context: ReactContext?) {
  context?.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
    ?.emit("toggleElementInspector", null)
}
