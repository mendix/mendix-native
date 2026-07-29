package com.mendix.mendixnative.react

import com.facebook.common.logging.FLog
import com.facebook.react.ReactApplication
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.devsupport.StackTraceHelper

class NativeErrorHandler(val reactContext: ReactApplicationContext) {
    fun handle(message: String?, stackTrace: ReadableArray?) {
        FLog.e(javaClass, "Received JS exception: $message")
        // In bridgeless mode, use DevSupportManager directly for proper error display
        val reactHost = (reactContext.applicationContext as? ReactApplication)?.reactHost
        reactHost?.devSupportManager?.showNewJSError(message, sanitize(stackTrace), -1)
    }

    /**
     * Filter out invalid stack frames to prevent parsing errors.
     *
     * React Native's StackTraceHelper.convertJsStackTrace() uses requireNotNull() for
     * methodName and file. Invalid frames cause secondary errors that break RedBox and reload.
     *
     * Simply skip frames that don't have the required non-null fields.
     */
    private fun sanitize(stackTrace: ReadableArray?): ReadableArray {
        val filtered = Arguments.createArray()
        if (stackTrace == null) return filtered
        (0 until stackTrace.size())
            .mapNotNull { stackTrace.getMap(it) }
            .filter { isValidFrame(it) }
            .forEach { filtered.pushMap(it) }

        return filtered
    }

    /**
     * Check if a stack frame has the required non-null fields for StackTraceHelper.
     * Uses React Native's own key constants to match their validation logic.
     */
    private fun isValidFrame(frame: ReadableMap): Boolean {
        return arrayOf(StackTraceHelper.FILE_KEY, StackTraceHelper.METHOD_NAME_KEY).all {
            frame.hasKey(it) && !frame.isNull(it)
        }
    }
}
