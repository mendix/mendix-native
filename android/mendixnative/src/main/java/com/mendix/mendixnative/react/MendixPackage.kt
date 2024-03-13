package com.mendix.mendixnative.react

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager
import com.mendix.mendixnative.encryption.MendixEncryptedStorageModule
import com.mendix.mendixnative.react.download.NativeDownloadModule
import com.mendix.mendixnative.react.fs.NativeFsModule
import com.mendix.mendixnative.react.ota.NativeOtaModule
import com.mendix.mendixnative.react.splash.MendixSplashScreenModule
import com.mendix.mendixnative.react.splash.MendixSplashScreenPresenter

class MendixPackage(private val splashScreenPresenter: MendixSplashScreenPresenter?) :
    ReactPackage {
    override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
        val modules = mutableListOf(
            MxConfiguration(reactContext),
            NativeErrorHandler(reactContext),
            NativeReloadHandler(reactContext),
            NativeFsModule(reactContext),
            NativeDownloadModule(reactContext),
            NativeOtaModule(reactContext),
            MendixEncryptedStorageModule(reactContext)
        )
        if (splashScreenPresenter != null) {
            modules.add(MendixSplashScreenModule(splashScreenPresenter, reactContext))
        }
        return modules
    }

    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return emptyList()
    }
}
