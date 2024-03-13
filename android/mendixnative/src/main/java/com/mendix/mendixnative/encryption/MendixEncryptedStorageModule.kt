package com.mendix.mendixnative.encryption

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.module.annotations.ReactModule
import com.mendix.mendixnative.encryption.MendixEncryptedStorage.Companion.getMendixEncryptedStorage

const val MODULE_NAME = "RNMendixEncryptedStorage"
const val STORE_NAME = "MENDIX_ENCRYPTED_STORAGE"

@ReactModule(name = MODULE_NAME)
class MendixEncryptedStorageModule(reactApplicationContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactApplicationContext) {
    override fun getName(): String = MODULE_NAME
    private val storage = getMendixEncryptedStorage(reactApplicationContext)

    @ReactMethod
    fun setItem(key: String, value: String, promise: Promise): Unit =
        storage.setItem(key, value).let {
            when (it) {
                true -> promise.resolve(null)
                false -> promise.reject(Exception("Failed to set item in encrypted store."))
            }
        }

    @ReactMethod
    fun getItem(key: String, promise: Promise): Unit =
        storage.getItem(key).let { promise.resolve(it) }

    @ReactMethod
    fun removeItem(key: String, promise: Promise): Unit =
        storage.removeItem(key).let {
            when (it) {
                true -> promise.resolve(null)
                false -> promise.reject(Exception("Failed to remove item $key from encrypted store."))
            }
        }

    @ReactMethod
    fun clear(promise: Promise): Unit = storage.clear().let {
        when (it) {
            true -> promise.resolve(null)
            false -> promise.reject(Exception("Failed to clear encrypted store."))
        }
    }

    override fun getConstants(): MutableMap<String, Any> {
        return mutableMapOf(
            "IS_ENCRYPTED" to storage.isEncrypted
        )
    }
}
