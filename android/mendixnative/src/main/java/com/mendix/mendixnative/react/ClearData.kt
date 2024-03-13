package com.mendix.mendixnative.react

import android.app.Application
import android.content.Context
import android.util.Log
import android.webkit.CookieManager
import android.widget.Toast
import com.facebook.react.ReactNativeHost
import com.facebook.react.bridge.JavaOnlyMap
import com.facebook.react.bridge.PromiseImpl
import com.facebook.react.bridge.ReactContext
import com.facebook.react.modules.network.NetworkingModule
import com.mendix.mendixnative.encryption.MendixEncryptedStorage
import com.mendix.mendixnative.react.fs.FileBackend
import com.reactnativecommunity.asyncstorage.AsyncStorageModule
import org.pgsqlite.SQLitePlugin
import java.io.File

fun clearData(applicationContext: Application) = clearCookies().also {
    clearCachedReactNativeDevBundle(applicationContext)
    val fileBackend = FileBackend(applicationContext)
    for (ending in listOf("", "-shm", "-wal")) {
        fileBackend.deleteFile(
            File(
                applicationContext.filesDir.parentFile,
                "databases/" + MxConfiguration.defaultDatabaseName + ending
            ).path
        )
        fileBackend.deleteFile(
            File(
                applicationContext.filesDir.parentFile,
                "databases/RKStorage$ending"
            ).path
        )
    }
    fileBackend.deleteDirectory(applicationContext.filesDir)
}

fun clearDataWithReactContext(
    applicationContext: Application,
    reactNativeHost: ReactNativeHost,
    cb: (success: Boolean) -> Unit
) {
    clearCachedReactNativeDevBundle(applicationContext)
    val reactContext = reactNativeHost.reactInstanceManager.currentReactContext
    val fileBackend = FileBackend(applicationContext)
    fileBackend.deleteDirectory(applicationContext.filesDir)
    val errorString = "Clearing %s failed. Please clear your data from the launch screen."


    // TODO: Investigate why delete appDatabaseAsync fires twice [NALM-248]
    // deleteAppDatabaseAsync is fired twice which results in the callback being called twice.
    // Therefore we created a fire once callback that should be fired only once on success or failure.
    deleteAppDatabaseAsync(reactContext, object : BooleanCallback {
        var fired = false

        override fun invoke(success: Boolean) {
            if (fired) return

            fired = true

            if (!success) {
                reportError("database")
            }

            if (!clearAsyncStorage(reactNativeHost)) {
                reportError("async storage")
            }

            clearSecureStorage(reactContext?.applicationContext)
            if (!success) {
                reportError("encrypted storage")
            }

            runOnUiThread {
                clearCookiesAsync(reactContext) { clearCookiesSuccessful ->
                    if (!clearCookiesSuccessful) {
                        reportError("cookies")
                        return@clearCookiesAsync
                    }
                    cb(true)
                }
            }
        }

        private fun reportError(operation: String) {
            Toast.makeText(
                applicationContext,
                String.format(errorString, operation),
                Toast.LENGTH_LONG
            ).show()
        }
    })
}

fun deleteAppDatabaseAsync(reactContext: ReactContext?, cb: BooleanCallback) = reactContext?.let {
    val map = JavaOnlyMap()
    map.putString("path", MxConfiguration.defaultDatabaseName)
    (reactContext.catalystInstance.getNativeModule("SQLite") as SQLitePlugin).delete(
        map,
        { cb(true) },
        { cb(false) })
} ?: cb(false)

fun clearAsyncStorage(reactNativeHost: ReactNativeHost): Boolean =
    reactNativeHost.reactInstanceManager.currentReactContext?.let {
        it.getNativeModule(AsyncStorageModule::class.java)?.clearSensitiveData()
        return true
    } ?: false


fun clearSecureStorage(context: Context?): Boolean =
    context?.let { MendixEncryptedStorage.getMendixEncryptedStorage(it).clear() } ?: false

fun clearCookiesAsync(reactContext: ReactContext?, cb: (success: Boolean) -> Unit) =
    reactContext?.let {
        reactContext.getNativeModule(NetworkingModule::class.java)?.clearCookies {
            cb(it[0] as Boolean)
        }
    } ?: cb(false)

fun clearCachedReactNativeDevBundle(applicationContext: Application) {
    try {
        val fileBackend = FileBackend(applicationContext)
        fileBackend.deleteFile(File(applicationContext.filesDir, "ReactNativeDevBundle.js").path)
    } catch (e: Exception) {
        Log.d("ClearData", "Clearing ReactNativeDevBundle skipped: $e")
    }
}

fun clearCookies() = CookieManager.getInstance()?.removeAllCookies(null)

interface BooleanCallback {
    operator fun invoke(res: Boolean)
}
