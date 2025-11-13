package com.mendix.mendixnative.react

import com.facebook.common.logging.FLog
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeMap
import com.facebook.react.modules.core.ExceptionsManagerModule

class NativeErrorHandler(val reactContext: ReactApplicationContext) {
    fun handle(message: String?, stackTrace: ReadableArray?) {
        reactContext.typeSafeNativeModule<ExceptionsManagerModule>()?.reportSoftException(message, stackTrace, 0.0)
        // updateExceptionMessage is not available in RN 0.77.1
        // ref: https://github.com/facebook/react-native/commit/4f47439a02183205ff6f68b1fc3bc392e78e4cb4
        // exceptionsManagerModule.updateExceptionMessage(message, stackTrace, 0);
        FLog.e(javaClass, "Received JS exception: $message")
    }
}
