package com.mendix.mendixnative

import android.app.Activity
import com.facebook.react.ReactHost
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

    // Must run before the first access to `reactHost` below (and before any reload).
    // `PackagerConnectionSettings.debugServerHost` caches its value in memory for the
    // lifetime of the process the first time it's read (e.g. by an eager dev-support
    // settings reload triggered as soon as ReactHost/DevSupportManager is constructed).
    // If that first read happens before we persist the real Metro host, RN falls back
    // to its hardcoded emulator default (10.0.2.2:8081) and keeps using it for the rest
    // of the process — even though the correct host is written to SharedPreferences —
    // which is why a fresh app process (restart) "fixes" it but reload within the same
    // process does not. Resolving/pushing the host here, before `reactHost` is touched,
    // avoids that stale cache entirely.
    if (hasRNDeveloperSupport) setupDeveloperApp(runtimeUrl, mendixApp)

    // Reload only if there's already a running instance.
    if (reactHost.currentReactContext != null) {
      reactHost.reload("Clean start for new Mendix app")
    }
    if (clearData) clearData(context.application)
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

    // Explicitly push the freshly resolved host into the live ReactHost's
    // PackagerConnectionSettings. Writing to SharedPreferences alone (above) isn't
    // enough if RN already cached a stale/default debug server host in memory for
    // this process — this overwrite takes effect immediately, regardless of when
    // that first (possibly premature) read happened.
    reactHost.devSupportManager?.devSettings?.packagerConnectionSettings?.debugServerHost =
      preferences.getMetroBundlerHost()

    clearCachedReactNativeDevBundle(context.application)
  }
}

interface DevAppMenuHandler {
  fun showDevAppMenu()
}
