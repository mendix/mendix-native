package com.mendix.mendixnative.encryption

import android.content.Context
import android.content.SharedPreferences
import android.util.Log

class MendixEncryptedStorage private constructor(context: Context) {
  var isEncrypted: Boolean private set
  private var store: SharedPreferences

  init {
    try {
      store = getEncryptedSharedPreferences(
        context,
        getMasterKey(context),
        STORE_NAME
      )
      isEncrypted = true
    } catch (e: Exception) {
      // On Android 5.0 (API level 21) and Android 5.1 (API level 22), you cannot use the Android keystore to store keysets.
      Log.e(
        MendixEncryptedStorage::class.simpleName,
        "Using unencrypted storage due to exception",
        e
      )
      store = context.getSharedPreferences(STORE_NAME, Context.MODE_PRIVATE)
      isEncrypted = false
    }
  }

  fun setItem(
    key: String,
    value:
    String,
  ): Boolean = store.edit().putString(key, value).commit()

  fun getItem(key: String): String? = store.getString(key, null)

  fun removeItem(key: String): Boolean = store.edit().remove(key).commit()

  fun clear(): Boolean = store.edit().clear().commit()

  companion object {
    private var instance: MendixEncryptedStorage? = null
    fun getMendixEncryptedStorage(context: Context): MendixEncryptedStorage {
      if (instance == null) instance = MendixEncryptedStorage(context)
      return instance!!
    }
  }
}
