package com.mendix.mendixnative.react.ota

import android.content.Context
import android.util.Log
import com.facebook.react.bridge.*
import com.mendix.mendixnative.react.MxConfiguration
import com.mendix.mendixnative.react.download.downloadFile
import com.mendix.mendixnative.react.fs.FileBackend
import okhttp3.OkHttpClient
import org.json.JSONObject
import java.io.File
import java.util.*


const val INVALID_RUNTIME_URL = "INVALID_RUNTIME_URL"
const val INVALID_DEPLOY_CONFIG = "INVALID_DEPLOY_CONFIG"
const val INVALID_DOWNLOAD_CONFIG = "INVALID_DOWNLOAD_CONFIG"
const val OTA_ZIP_FILE_MISSING = "OTA_ZIP_FILE_MISSING"
const val OTA_UNZIP_DIR_EXISTS = "OTA_UNZIP_DIR_EXISTS"
const val OTA_DEPLOYMENT_FAILED = "OTA_DEPLOYMENT_FAILED"
const val OTA_DOWNLOAD_FAILED = "OTA_DOWNLOAD_FAILED"

const val MANIFEST_OTA_DEPLOYMENT_ID_KEY = "otaDeploymentID"
const val MANIFEST_RELATIVE_BUNDLE_PATH_KEY = "relativeBundlePath"
const val MANIFEST_APP_VERSION_KEY = "appVersion"
const val DOWNLOAD_RESULT_OTA_PACKAGE_KEY = "otaPackage"
const val DEPLOY_CONFIG_DEPLOYMENT_ID_KEY = "otaDeploymentID"
const val DEPLOY_CONFIG_OTA_PACKAGE_KEY = DOWNLOAD_RESULT_OTA_PACKAGE_KEY
const val DEPLOY_CONFIG_EXTRACTION_DIR_KEY = "extractionDir"

const val TAG = "OTA"

class NativeOtaModule(
  val reactApplicationContext: ReactApplicationContext,
  getOtaDir: (context: Context) -> String = { c ->
    com.mendix.mendixnative.react.ota.getOtaDir(
      c
    )
  },
  val getAppVersion: (context: Context) -> String = { c: Context ->
    resolveAppVersion(c)
  },
  val getOtaManifestFilepath: (context: Context) -> String = { c ->
    com.mendix.mendixnative.react.ota.getOtaManifestFilepath(c)
  },
  val resolveAbsolutePathRelativeToOtaDir: (context: Context, relativePath: String) -> String = { c, relativePath ->
    com.mendix.mendixnative.react.ota.resolveAbsolutePathRelativeToOtaDir(c, relativePath)
  },
) {
  private val fileBackend = FileBackend(reactApplicationContext)
  private val otaDir: String = getOtaDir(reactApplicationContext)

  init {
    // Ensure the dir exist
    File(otaDir).mkdirs()
  }

  /**
   * Accepts a structure of:
   * {
   *    url: string, // url to download from
   * }
   *
   * Returns a structure of:
   * {
   *    otaPackage: string // zip file name
   * }
   */
  fun download(config: ReadableMap, promise: Promise) {
    Log.i(TAG, "Downloading...")
    val url = config.getString("url") ?: return promise.reject(
      INVALID_DOWNLOAD_CONFIG,
      "Key url is invalid."
    )
    if (MxConfiguration.runtimeUrl == null || !url.startsWith(MxConfiguration.runtimeUrl!!)) {
      return promise.reject(INVALID_RUNTIME_URL, "Invalid OTA URL.")
    }

    val zipFileName = generateZipFilename()
    downloadFile(
      client = OkHttpClient(),
      url = url,
      downloadPath = getOtaZipFilePath(
        reactApplicationContext,
        zipFileName
      ),
      onSuccess = {
        Log.i(TAG, "OTA downloaded.")
        promise.resolve(WritableNativeMap().also {
          it.putString(DOWNLOAD_RESULT_OTA_PACKAGE_KEY, zipFileName)
        })
      },
      onFailure = {
        Log.e(TAG, "OTA download failed.")
        promise.reject(OTA_DOWNLOAD_FAILED, it)
      }
    )
  }

  /**
   * Accepts a structure:
   * {
   *    otaDeploymentID: string, // current ota deployment id
   *    otaPackage: string, // the zip filename to unzip
   *    extractionDir: string, // the relative path to extract the bundle to
   * }
   *
   * Generates a manifest.json:
   * {
   *   otaDeploymentID: string, // current ota deployment id
   *   relativeBundlePath: string, // relative path to the index.*.bundle
   *   appVersion: string // Version number + version at the installation time
   * }
   */
  fun deploy(deployConfig: ReadableMap, promise: Promise) {

    val otaDeploymentID = deployConfig.getStringOrNull(DEPLOY_CONFIG_DEPLOYMENT_ID_KEY)
      ?: return promise.reject(
        INVALID_DEPLOY_CONFIG,
        "Key $DEPLOY_CONFIG_DEPLOYMENT_ID_KEY is invalid."
      )
    val zipFile = File(
      getOtaZipFilePath(
        reactApplicationContext,
        deployConfig.getStringOrNull(DEPLOY_CONFIG_OTA_PACKAGE_KEY)
          ?: return promise.reject(
            INVALID_DEPLOY_CONFIG,
            "Key $DEPLOY_CONFIG_OTA_PACKAGE_KEY is invalid."
          )
      )
    )
    val extractionDir = File(
      otaDir,
      deployConfig.getStringOrNull(DEPLOY_CONFIG_EXTRACTION_DIR_KEY)
        ?: return promise.reject(
          INVALID_DEPLOY_CONFIG,
          "Key $DEPLOY_CONFIG_EXTRACTION_DIR_KEY is invalid."
        )
    )
    val oldManifest = readManifestJson(reactApplicationContext, fileBackend)

    Log.i(TAG, "Deploying ota with id: $otaDeploymentID")

    if (!zipFile.exists()) {
      return reject(promise, OTA_ZIP_FILE_MISSING, "OTA package does not exist")
    }

    if (extractionDir.exists()) {
      Log.w(TAG, "Unzip directory exists. Removing it...")
      fileBackend.deleteDirectory(extractionDir.absolutePath)
    }

    try {
      Log.i(TAG, "Unzipping bundle...")
      fileBackend.unzip(zipFile, extractionDir)

      fileBackend.writeUnencryptedJson(
        OtaManifest(
          otaDeploymentID = otaDeploymentID,
          relativeBundlePath = File(
            extractionDir.relativeTo(File(otaDir)),
            "index.android.bundle"
          ).path,
          appVersion = getAppVersion(reactApplicationContext)
        ).toHasMap(), getOtaManifestFilepath(reactApplicationContext)
      )

      // Old bundle cleanup
      val shouldRemoveOldBundle =
        oldManifest != null && oldManifest.otaDeploymentID != otaDeploymentID
      if (shouldRemoveOldBundle) {
        File(
          resolveAbsolutePathRelativeToOtaDir(
            reactApplicationContext,
            oldManifest.relativeBundlePath
          )
        ).parentFile?.deleteRecursively()
      }
      zipFile.delete()
    } catch (e: Exception) {
      extractionDir.deleteRecursively()
      return reject(promise, OTA_DEPLOYMENT_FAILED, "OTA deployment failed", e)
    }
    Log.i(TAG, "OTA deployed.")
    promise.resolve(null)
  }
  private fun generateZipFilename(): String {
    return "${UUID.randomUUID()}.zip"
  }

  private fun getOtaZipFilePath(context: Context, fileName: String): String =
    resolveAbsolutePathRelativeToOtaDir(context, fileName)

  private fun reject(
    promise: Promise,
    code: String,
    message: String,
    throwable: Throwable? = null
  ) {
    Log.e(TAG, message)
    promise.reject(code, message, throwable)
  }
}

private fun ReadableMap.getStringOrNull(key: String): String? {
  return try {
    this.getString(key)
  } catch (_: Exception) {
    null
  }
}

fun readManifestJson(context: Context, fileBackend: FileBackend): OtaManifest? {
  return try {
    val data = fileBackend.readAsUnencryptedFile(getOtaManifestFilepath(context))
    val json = JSONObject(String(data))
    return OtaManifest(
      otaDeploymentID = json.getString(MANIFEST_OTA_DEPLOYMENT_ID_KEY),
      relativeBundlePath = json.getString(MANIFEST_RELATIVE_BUNDLE_PATH_KEY),
      appVersion = json.getString(MANIFEST_APP_VERSION_KEY)
    )
  } catch (_: Exception) {
    null
  }
}

data class OtaManifest(
  val otaDeploymentID: String,
  val relativeBundlePath: String,
  val appVersion: String
)

fun OtaManifest.toHasMap(): HashMap<String, Any> {
  return hashMapOf(
    MANIFEST_OTA_DEPLOYMENT_ID_KEY to otaDeploymentID,
    MANIFEST_RELATIVE_BUNDLE_PATH_KEY to relativeBundlePath,
    MANIFEST_APP_VERSION_KEY to appVersion
  )
}
