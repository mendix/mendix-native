package com.mendix.mendixnative.react.ota

import android.content.Context
import android.os.Build
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
  ).let { info ->
    info.versionName.let { versionName ->
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
        "$versionName-${info.longVersionCode}"
      else
        "$versionName-${info.versionCode}"
    }
  }
}

fun getNativeDependencies(context: Context): Map<String, String> {
  val nativeDependencies = ResourceReader.readString(context, "native_dependencies")
  if (nativeDependencies.isEmpty()) {
    return emptyMap()
  }
  val typeRef = object : TypeReference<HashMap<String, String>>() {}
  return ObjectMapper().readValue(nativeDependencies, typeRef).toMap()
}
