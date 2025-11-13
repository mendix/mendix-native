package com.mendix.mendixnative.react

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeMap
import com.mendix.mendixnative.MendixApplication
import com.mendix.mendixnative.config.AppUrl
import com.mendix.mendixnative.react.ota.getNativeDependencies
import com.mendix.mendixnative.react.ota.getOtaManifestFilepath

class MxConfiguration(val reactContext: ReactApplicationContext) {

  fun getConstants(): WritableMap? {
    val application = (reactContext.applicationContext as MendixApplication)
    if (runtimeUrl == null) {
      if (warningsFilter != WarningsFilter.none) {
        application.reactNativeHost
          .reactInstanceManager
          .devSupportManager
          .showNewJavaError(
            "Runtime URL not specified.",
            Throwable("Without the runtime URL, the app cannot retrieve any data.\n\nPlease redeploy the app.")
          )

        return WritableNativeMap()
      }

      throw IllegalStateException("Runtime URL not set in the MxConfiguration")
    }

    val constants = WritableNativeMap()
    constants.putString("RUNTIME_URL", AppUrl.forRuntime(runtimeUrl))
    constants.putString("APP_NAME", defaultAppName)
    constants.putString("DATABASE_NAME", defaultDatabaseName)
    constants.putString(
      "FILES_DIRECTORY_NAME",
      defaultFilesDirectoryName
    ) // Not to be removed as it is required for backwards compatibility.
    constants.putString("WARNINGS_FILTER_LEVEL", warningsFilter.toString())
    constants.putString("OTA_MANIFEST_PATH", getOtaManifestFilepath(reactContext))
    constants.putBoolean("IS_DEVELOPER_APP", application.getUseDeveloperSupport())
    constants.putInt("NATIVE_BINARY_VERSION", NATIVE_BINARY_VERSION)
    constants.putString("APP_SESSION_ID", application.getAppSessionId())

    val dependencies = WritableNativeMap()
    getNativeDependencies(reactContext).forEach {
      dependencies.putString(it.key, it.value)
    }
    constants.putMap("NATIVE_DEPENDENCIES", dependencies)

    return constants
  }

  enum class WarningsFilter {
    all, partial, none
  }

  companion object {
    /**
     * Side note for 11: I've bumped the nativeBinaryVersion from 12 to 30,
     * because there needs to be version increment space for Mx 10.24.
     * You can remove this comment when the next version is released.
     *
     *
     * Increment nativeBinaryVersion to 30 for OP-SQlite database migration
     */
    const val NATIVE_BINARY_VERSION: Int = 30
    const val NAME: String = "MxConfiguration"
    var defaultDatabaseName: String = "default"

    @Deprecated("")
    var defaultFilesDirectoryName: String = "files/default"

    var defaultAppName: String? = null
    var runtimeUrl: String? = null
    var warningsFilter: WarningsFilter? = null

    /**
     * Setter for the application name constant
     *
     * @param name the unique name or identifier that represents the application. This value should always be set to null for non-sample apps
     */
    fun setDefaultAppNameOrDefault(name: String?) {
      defaultAppName = name
    }

    fun setDefaultDatabaseNameOrDefault(name: String?) {
      defaultDatabaseName = name ?: "default"
    }

    fun setDefaultFilesDirectoryOrDefault(path: String?) {
      defaultFilesDirectoryName = path ?: "files/default"
    }
  }
}
