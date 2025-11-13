package com.mendix.mendixnative.encryption

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.mendix.mendixnative.encryption.MendixEncryptedStorage.Companion.getMendixEncryptedStorage

const val STORE_NAME = "MENDIX_ENCRYPTED_STORAGE"

class MendixEncryptedStorageModule(context: ReactApplicationContext) {
  private val storage = getMendixEncryptedStorage(context)

  val isEncrypted = storage.isEncrypted

  fun setItem(key: String, value: String, promise: Promise): Unit =
    storage.setItem(key, value).let {
      when (it) {
        true -> promise.resolve(null)
        false -> promise.reject(Exception("Failed to set item in encrypted store."))
      }
    }

  fun getItem(key: String, promise: Promise): Unit =
    storage.getItem(key).let { promise.resolve(it) }

  fun removeItem(key: String, promise: Promise): Unit =
    storage.removeItem(key).let {
      when (it) {
        true -> promise.resolve(null)
        false -> promise.reject(Exception("Failed to remove item $key from encrypted store."))
      }
    }

  fun clear(promise: Promise): Unit = storage.clear().let {
    when (it) {
      true -> promise.resolve(null)
      false -> promise.reject(Exception("Failed to clear encrypted store."))
    }
  }
}
