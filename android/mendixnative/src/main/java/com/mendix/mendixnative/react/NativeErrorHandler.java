package com.mendix.mendixnative.react;

import com.facebook.common.logging.FLog;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.modules.core.ExceptionsManagerModule;

import org.jetbrains.annotations.NotNull;

// Used by previous versions of the client (<= 9.15)
@ReactModule(name = NativeErrorHandler.NAME)
public class NativeErrorHandler extends ReactContextBaseJavaModule {
    static final String NAME = "NativeErrorHandler";

    NativeErrorHandler(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @NotNull
    @Override
    public String getName() {
        return NAME;
    }

    @ReactMethod
    public void handle(String message, ReadableArray stackTrace) {
        ExceptionsManagerModule exceptionsManagerModule = getReactApplicationContext().getNativeModule(ExceptionsManagerModule.class);
        exceptionsManagerModule.reportSoftException(message, stackTrace, 0);
        exceptionsManagerModule.updateExceptionMessage(message, stackTrace, 0);

        FLog.e(getClass(), "Received JS exception: " + message);
    }
}
