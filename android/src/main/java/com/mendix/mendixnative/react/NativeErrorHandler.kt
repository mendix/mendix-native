package com.mendix.mendixnative.react

import com.facebook.common.logging.FLog
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.modules.core.ExceptionsManagerModule

/**
 * Handles JavaScript exceptions by reporting them to React Native's ExceptionsManager.
 *
 * This bridges JavaScript errors to the native exception handling system.
 */
class NativeErrorHandler(val reactContext: ReactApplicationContext) {
    fun handle(message: String?, stackTrace: ReadableArray?) {
        // Use typed module access instead of generic typeSafeNativeModule
        val exceptionsManagerModule = reactContext.getNativeModule(ExceptionsManagerModule::class.java)
        exceptionsManagerModule?.reportSoftException(message, stackTrace, 0.0)

        // Note: updateExceptionMessage is not available in RN 0.77.1+
        // ref: https://github.com/facebook/react-native/commit/4f47439a02183205ff6f68b1fc3bc392e78e4cb4

        FLog.e(javaClass, "Received JS exception: $message")
    }
}
