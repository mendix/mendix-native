package com.mendix.mendixnative.react

import com.facebook.react.bridge.ReactApplicationContext
import com.mendix.mendixnative.MendixApplication
import com.mendix.mendixnative.config.AppUrl
import com.mendix.mendixnative.react.ota.getNativeDependencies
import com.mendix.mendixnative.react.ota.getOtaManifestFilepath

class MxConfiguration(val reactContext: ReactApplicationContext) {

  fun getConstants(): Map<String, Any> {
    val application = (reactContext.applicationContext as MendixApplication)
    if (runtimeUrl == null) {
      if (warningsFilter != WarningsFilter.none) {
        application.reactHost
          ?.devSupportManager
          ?.showNewJavaError(
            "Runtime URL not specified.",
            Throwable("Without the runtime URL, the app cannot retrieve any data.\n\nPlease redeploy the app.")
          )

        return emptyMap()
      }

      throw IllegalStateException("Runtime URL not set in the MxConfiguration")
    }

    val constants = mutableMapOf(
      "RUNTIME_URL" to AppUrl.forRuntime(runtimeUrl),
      "DATABASE_NAME" to defaultDatabaseName,
      "FILES_DIRECTORY_NAME" to defaultFilesDirectoryName,
      "WARNINGS_FILTER_LEVEL" to warningsFilter.toString(),
      "OTA_MANIFEST_PATH" to getOtaManifestFilepath(reactContext),
      "IS_DEVELOPER_APP" to application.getUseDeveloperSupport(),
      "NATIVE_BINARY_VERSION" to NATIVE_BINARY_VERSION,
      "APP_SESSION_ID" to application.getAppSessionId(),
      "NATIVE_DEPENDENCIES" to getNativeDependencies(reactContext)
    )
    defaultAppName?.let {
      constants.put("APP_NAME", it)
    }

    return constants
  }

  enum class WarningsFilter {
    all, partial, none
  }

  companion object {
    const val NATIVE_BINARY_VERSION: Int = 32
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
