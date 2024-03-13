package com.mendix.mendixnative.react

import android.os.Handler
import android.os.Looper
import com.facebook.common.logging.FLog
import com.facebook.react.ReactApplication
import com.facebook.react.bridge.JSBundleLoader
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.mendix.mendixnative.MendixApplication
import com.mendix.mendixnative.activity.LaunchScreenHandler
import com.mendix.mendixnative.util.ReflectionUtils

@ReactModule(name = NativeReloadHandler.NAME)
class NativeReloadHandler internal constructor(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {
    override fun getName(): String {
        return NAME
    }

    @ReactMethod
    fun reload() {
        FLog.i(javaClass, "Reload bundle triggered from JS")
        (reactApplicationContext.currentActivity as? LaunchScreenHandler)?.let {
            postOnMainThread {
                it.showLaunchScreen()
            }
        }
            ?: FLog.e(
                javaClass,
                "Activity does not implement LaunchScreenHandler, skipping showing launch screen"
            )
        handleJSBundleLoading()
        reloadWithoutState()
    }

    @ReactMethod
    fun exitApp() {
        reactApplicationContext?.currentActivity?.finishAffinity()
    }

    private fun reloadWithoutState() {
        postOnMainThread {
            (reactApplicationContext.applicationContext as ReactApplication)
                .reactNativeHost
                .reactInstanceManager
                .recreateReactContextInBackground()
        }

    }

    fun reloadClientWithState() =
        reactApplicationContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit("reloadWithState", null)

    companion object {
        const val NAME = "NativeReloadHandler"
    }

    private fun postOnMainThread(cb: () -> Unit) {
        Handler(Looper.getMainLooper()).post {
            cb.invoke()
        }
    }

    private fun handleJSBundleLoading() {
        val bundle = (reactApplicationContext.applicationContext as MendixApplication).jsBundleFile
        val instanceManager =
            (reactApplicationContext.applicationContext as ReactApplication).reactNativeHost.reactInstanceManager

        val latestJSBundleLoader = if (bundle != null) {
            getAssetLoader(bundle)
        } else {
            getAssetLoader("assets://index.android.bundle")
        }

        ReflectionUtils.setField(instanceManager, "mBundleLoader", latestJSBundleLoader)
        ReflectionUtils.setField(
            instanceManager,
            "mUseDeveloperSupport",
            (reactApplicationContext.applicationContext as MendixApplication).useDeveloperSupport
        )
    }

    override fun getConstants(): MutableMap<String, Any> {
        return mutableMapOf(Pair("EVENT_RELOAD_WITH_STATE", "reloadWithState"))
    }

    private fun getAssetLoader(bundle: String): JSBundleLoader? {
        return when {
            bundle.startsWith("assets://") -> JSBundleLoader.createAssetLoader(
                reactApplicationContext,
                bundle,
                false
            )
            else -> JSBundleLoader.createFileLoader(bundle)
        }
    }
}
