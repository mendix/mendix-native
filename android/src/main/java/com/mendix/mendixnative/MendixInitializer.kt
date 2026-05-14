package com.mendix.mendixnative

import android.app.Activity
import android.view.MotionEvent
import com.facebook.react.ReactHost
import com.facebook.react.common.ShakeDetector
import com.facebook.react.devsupport.DevSupportManagerBase
import com.facebook.react.devsupport.attachMendixSupportManagerShakeDetector
import com.facebook.react.devsupport.makeShakeDetector
import com.facebook.react.modules.network.OkHttpClientProvider
import com.mendix.mendixnative.config.AppPreferences
import com.mendix.mendixnative.handler.DevMenuTouchEventHandler
import com.mendix.mendixnative.react.*
import com.mendix.mendixnative.request.MendixNetworkInterceptor
import com.mendix.mendixnative.util.CookieEncryption
import com.mendix.mendixnative.react.MxConfiguration
import com.mendix.mendixnative.react.clearCachedReactNativeDevBundle
import com.mendix.mendixnative.react.clearData
import com.mendix.mendixnative.react.closeSqlDatabaseConnection

class MendixInitializer(
  private val context: Activity,
  private val reactHost: ReactHost,
  private val hasRNDeveloperSupport: Boolean = false,
) {
  private var shakeDetector: ShakeDetector? = null
  private var devMenuTouchEventHandler: DevMenuTouchEventHandler? = null

  fun onCreate(mendixApp: MendixApp, clearData: Boolean) {
    // Assign mendix xas id interceptor to okhttp
    CookieEncryption.init(this.context)
    if (CookieEncryption.isCookieEncryptionEnabled()) {
      OkHttpClientProvider.setOkHttpClientFactory {
        OkHttpClientProvider.createClientBuilder()
          .addNetworkInterceptor(MendixNetworkInterceptor())
          .build()
      }
    }

    val runtimeUrl = mendixApp.runtimeUrl
    MxConfiguration.runtimeUrl = runtimeUrl
    MxConfiguration.warningsFilter = mendixApp.warningsFilter

    // Destroy any existing ReactInstance so we start fresh, but do NOT invalidate —
    // invalidate() is terminal in bridgeless mode and prevents the host from ever being reused.
    reactHost.destroy("Clean start for new Mendix app", null)
    if (clearData) clearData(context.application)
    if (hasRNDeveloperSupport) setupDeveloperApp(runtimeUrl, mendixApp)
  }

  fun onDestroy() {
    // Stop shaking as early as possible to avoid orphaned dialogs
    stopShakeDetector()

    if (hasRNDeveloperSupport) {
      AppPreferences(context.applicationContext).setElementInspector(false)
    }
    // Destroy the current instance but keep the host reusable — invalidate() is terminal
    // in bridgeless mode and would prevent the host from ever starting a new instance.
    reactHost.destroy("MendixInitializer.onDestroy()", null)

    // We need to close all databases separately to avoid hitting a read only state exception
    // Databases need to close after we are done closing the react native host to avoid db locks
    closeSqlDatabaseConnection(reactHost.currentReactContext)
  }

  fun stopShakeDetector() {
    shakeDetector?.stop()
  }

  fun dispatchTouchEvent(ev: MotionEvent?): Boolean {
    return devMenuTouchEventHandler?.handle(ev) ?: false
  }

  private fun attachShakeDetector(devAppMenuHandler: DevAppMenuHandler) {
    if (shakeDetector == null) {
      shakeDetector = makeShakeDetector(context.applicationContext) {
        devAppMenuHandler.showDevAppMenu()
      }
    }

    (reactHost.devSupportManager as? DevSupportManagerBase)?.run {
        attachMendixSupportManagerShakeDetector(shakeDetector!!, this)
    }
  }

  private fun setupDeveloperApp(
    runtimeUrl: String,
    mendixApp: MendixApp
  ) {
    val preferences = AppPreferences(context.applicationContext)
    preferences.updatePackagerHost(runtimeUrl)
    preferences.setRemoteDebugging(false)
    preferences.setDeltas(false)
    preferences.setDevMode((mendixApp.showExtendedDevMenu))

    clearCachedReactNativeDevBundle(context.application)
  }
}

interface DevAppMenuHandler {
  fun showDevAppMenu()
}
