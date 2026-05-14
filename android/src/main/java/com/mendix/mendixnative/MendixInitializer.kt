package com.mendix.mendixnative

import android.app.Activity
import com.facebook.react.ReactHost
import com.facebook.react.devsupport.DevSupportManagerBase
import com.facebook.react.modules.network.OkHttpClientProvider
import com.mendix.mendixnative.config.AppPreferences
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

    // Reload only if there's already a running instance.
    if (reactHost.currentReactContext != null) {
      reactHost.reload("Clean start for new Mendix app")
    }
    if (clearData) clearData(context.application)
    if (hasRNDeveloperSupport) setupDeveloperApp(runtimeUrl, mendixApp)
  }

  fun onDestroy() {
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
