package com.mendix.mendixnative.util

import android.content.Context
import android.content.pm.PackageManager

object CookieEncryption {
    private var cookieEncryptionEnabled: Boolean = false
    private var isInitialized = false

    @JvmStatic
    fun init(context: Context) {
        if (!isInitialized) {
            try {
                val appInfo = context.packageManager.getApplicationInfo(
                    context.packageName, PackageManager.GET_META_DATA
                )
                cookieEncryptionEnabled = appInfo.metaData?.getBoolean("mendixnative.cookieEncryption", false) ?: false
            } catch (e: PackageManager.NameNotFoundException) {
                e.printStackTrace()
            }
            isInitialized = true
        }
    }

    fun isCookieEncryptionEnabled(): Boolean = cookieEncryptionEnabled
}
