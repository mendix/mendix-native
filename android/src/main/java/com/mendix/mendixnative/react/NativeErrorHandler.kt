package com.mendix.mendixnative.react

import com.facebook.common.logging.FLog
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.modules.core.ExceptionsManagerModule

class NativeErrorHandler(val reactContext: ReactApplicationContext) {
    fun handle(message: String?, stackTrace: ReadableArray?) {
        reactContext.nativeModule<ExceptionsManagerModule>(ExceptionsManagerModule.NAME)?.reportSoftException(message, stackTrace, 0.0)
        FLog.e(javaClass, "Received JS exception: $message")
    }
}
