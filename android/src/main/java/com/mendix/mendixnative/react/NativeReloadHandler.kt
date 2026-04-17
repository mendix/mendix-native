package com.mendix.mendixnative.react

import android.os.Handler
import android.os.Looper
import com.facebook.common.logging.FLog
import com.facebook.react.ReactApplication
import com.facebook.react.bridge.ReactApplicationContext
import com.mendix.mendixnative.activity.LaunchScreenHandler

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
        reloadWithoutState()
    }

    fun exitApp() {
        context.currentActivity?.finishAffinity()
    }

    // In the New Architecture (Bridgeless), reactHost.reload() destroys and recreates the
    // React instance, which re-invokes the JSBundleLoader provided to ReactHostImpl at
    // construction time. MendixReactApplication supplies a *dynamic* JSBundleLoader whose
    // loadScript() calls MendixReactApplication.getJSBundleFile() on every reload, so OTA
    // bundle changes are picked up automatically — no manual bundle swapping is needed.
    //
    // See ReactHostImpl.getOrCreateReloadTask() → getOrCreateReactInstanceTask() →
    //   jsBundleLoader.onSuccess { instance.loadJSBundle(bundleLoader) }
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
}
