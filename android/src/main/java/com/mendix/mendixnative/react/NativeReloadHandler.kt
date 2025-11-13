package com.mendix.mendixnative.react

import android.os.Handler
import android.os.Looper
import com.facebook.common.logging.FLog
import com.facebook.react.ReactApplication
import com.facebook.react.bridge.JSBundleLoader
import com.facebook.react.bridge.ReactApplicationContext
import com.mendix.mendixnative.MendixApplication
import com.mendix.mendixnative.activity.LaunchScreenHandler
import com.mendix.mendixnative.util.ReflectionUtils
import com.op.sqlite.OPSQLiteModule

class NativeReloadHandler(val context: ReactApplicationContext) {

    fun reload() {
        FLog.i(javaClass, "Reload bundle triggered from JS")
        (context.currentActivity as? LaunchScreenHandler)?.let {
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

    fun exitApp() {
        context.currentActivity?.finishAffinity()
    }

    private fun reloadWithoutState() {
        val reactHost = (context.applicationContext as? ReactApplication)?.reactHost
        postOnMainThread {
            if (reactHost != null) {
                reactHost.reload("Reload action from client")
            } else {
                FLog.e(javaClass, "Application context is not a ReactApplication")
            }
        }
    }

    private fun postOnMainThread(cb: () -> Unit) {
        Handler(Looper.getMainLooper()).post {
            cb.invoke()
        }
    }

    private fun handleJSBundleLoading() {
        val bundle = (context.applicationContext as MendixApplication).jsBundleFile
        val instanceManager =
            (context.applicationContext as ReactApplication).reactNativeHost.reactInstanceManager

        val latestJSBundleLoader = if (bundle != null) {
            getAssetLoader(bundle)
        } else {
            getAssetLoader("assets://index.android.bundle")
        }

        ReflectionUtils.setField(instanceManager, "mBundleLoader", latestJSBundleLoader)
        ReflectionUtils.setField(
            instanceManager,
            "mUseDeveloperSupport",
            (context.applicationContext as MendixApplication).useDeveloperSupport
        )
    }

    private fun getAssetLoader(bundle: String): JSBundleLoader? {
        return when {
            bundle.startsWith("assets://") -> JSBundleLoader.createAssetLoader(
                context,
                bundle,
                false
            )

            else -> JSBundleLoader.createFileLoader(bundle)
        }
    }
}
