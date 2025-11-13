package com.mendix.mendixnative.react.ota

import android.content.Context
import com.mendix.mendixnative.JSBundleFileProvider
import com.mendix.mendixnative.react.fs.FileBackend
import java.io.File

/*
* Returns the OTA bundle's location URL if an OTA bundle has bee downloaded and deployed.
* It:
* 	- Reads the OTA manifest.json
*	- Verifies current app version matches the OTA's deployed app version
*	- Verifies a bundle exists in the location expected
* 	- Returns the absolute path to the OTA bundle if it succeeds
*/
class OtaJSBundleUrlProvider : JSBundleFileProvider {
  override fun getJSBundleFile(context: Context): String? {
    val manifestFilePath = getOtaManifestFilepath(context)
    if (!File(manifestFilePath).exists()) return null

    val manifest = readManifestJson(context, FileBackend(context))
      ?: return null

    // If the app version does not match the manifest version we assume the app has been updated/downgraded
    // In this case do not use the OTA bundle.
    if (manifest.appVersion != resolveAppVersion(context)) {
      return null
    }
    val bundlePath = manifest.relativeBundlePath
    val relativeBundlePath = resolveAbsolutePathRelativeToOtaDir(context, bundlePath)
    if (!File(relativeBundlePath).exists()) return null
    return relativeBundlePath
  }
}
