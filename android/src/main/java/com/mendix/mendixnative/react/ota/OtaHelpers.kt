package com.mendix.mendixnative.react.ota

import android.content.Context
import com.fasterxml.jackson.core.type.TypeReference
import com.fasterxml.jackson.databind.ObjectMapper
import com.mendix.mendixnative.util.ResourceReader
import java.io.File
import java.util.*

const val OTA_DIR_NAME = "Ota"
const val MANIFEST_FILE_NAME = "manifest.json"

fun resolveAbsolutePathRelativeToOtaDir(context: Context, path: String): String =
  File(getOtaDir(context), path).absolutePath

fun getOtaDir(context: Context): String = File(context.filesDir.parent, OTA_DIR_NAME).absolutePath
fun getOtaManifestFilepath(context: Context): String =
  resolveAbsolutePathRelativeToOtaDir(context, MANIFEST_FILE_NAME)

fun resolveAppVersion(context: Context): String {
  return context.packageManager.getPackageInfo(
    context.packageName,
    0
  ).let { info -> "${info.versionName}-${info.longVersionCode}" }
}

fun getNativeDependencies(context: Context): Map<String, String> {
  val nativeDependencies = ResourceReader.readString(context, "native_dependencies")
  if (nativeDependencies.isEmpty()) {
    return emptyMap()
  }
  val typeRef = object : TypeReference<HashMap<String, String>>() {}
  return ObjectMapper().readValue(nativeDependencies, typeRef).toMap()
}

/**
 * Resolves [path] against [otaDir] and returns it only if it stays strictly inside [otaDir],
 * so paths received from JS or read from the manifest can't point elsewhere in the app's storage.
 */
fun resolvePathInsideOtaDir(otaDir: String, path: String): File? {
  val root = File(otaDir).canonicalFile
  val file = File(otaDir, path)
  return if (file.canonicalPath.startsWith(root.path + File.separator)) file else null
}
