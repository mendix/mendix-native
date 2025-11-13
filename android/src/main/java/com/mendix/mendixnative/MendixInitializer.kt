package com.mendix.mendixnative

import android.app.Activity
import android.view.MotionEvent
import com.facebook.react.ReactHost
import com.facebook.react.ReactInstanceEventListener
import com.facebook.react.ReactNativeHost
import com.facebook.react.bridge.ReactContext
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
import com.mendix.mendixnative.react.toggleElementInspector
import com.mendixnative.MendixNativeModule

class MendixInitializer(
  private val context: Activity,
  private val reactHost: ReactHost,
  private val reactNativeHost: ReactNativeHost,
  private val hasRNDeveloperSupport: Boolean = false,
) : ReactInstanceEventListener {
  private var shakeDetector: ShakeDetector? = null
  private var devMenuTouchEventHandler: DevMenuTouchEventHandler? = null

  fun onCreate(
    mendixApp: MendixApp,
    devAppMenuHandler: DevAppMenuHandler = object : DevAppMenuHandler {
      override fun showDevAppMenu() {}
    },
    clearData: Boolean,
  ) {
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

    // This is here to make sure that a clean host instance is initialised.
    restartReactInstanceManager()
    if (clearData) clearData(context.application)
    if (hasRNDeveloperSupport) setupDeveloperApp(runtimeUrl, mendixApp)
    if (mendixApp.attachCustomDeveloperMenu) attachCustomDeveloperMenu(devAppMenuHandler)
  }

  private fun restartReactInstanceManager() {
    if (reactNativeHost.hasInstance()) reactNativeHost.clear()
    // Pre-initialize reactInstanceManager to be available for other methods
    if (reactNativeHost.hasInstance()) reactNativeHost.reactInstanceManager
  }

  private fun attachCustomDeveloperMenu(devAppMenuHandler: DevAppMenuHandler) {
    devMenuTouchEventHandler =
      DevMenuTouchEventHandler(object : DevMenuTouchEventHandler.DevMenuTouchListener {
        override fun onTap() {
          reactNativeHost.typeSafeNativeModule<MendixNativeModule>()?.reloadClientWithState()
        }

        override fun onLongPress() {
          devAppMenuHandler.showDevAppMenu()
        }
      })

    attachShakeDetector(devAppMenuHandler)
  }

  fun onDestroy() {
    // Stop shaking as early as possible to avoid orphaned dialogs
    stopShakeDetector()

    if (hasRNDeveloperSupport) {
      AppPreferences(context.applicationContext).setElementInspector(false)
      reactHost.removeReactInstanceEventListener(this)
    }

    // We need to clear the host to allow for reinitialization of the Native Modules
    // Especially for when switching between apps
    reactNativeHost.clear()

    // We need to close all databases separately to avoid hitting a read only state exception
    // Databases need to close after we are done closing the react native host to avoid db locks
    closeSqlDatabaseConnection(reactNativeHost.reactApplicationContext())
  }

  fun stopShakeDetector() {
    shakeDetector?.stop()
  }

  override fun onReactContextInitialized(context: ReactContext) {
    val preferences = AppPreferences(context)
    if (preferences.isElementInspectorEnabled) {
      toggleElementInspector(context)
    }
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
    reactHost.addReactInstanceEventListener(this)
  }
}

interface DevAppMenuHandler {
  fun showDevAppMenu()
}
