package com.mendixnative.encryption

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.annotations.ReactModule
import com.mendix.mendixnative.encryption.MendixEncryptedStorageModule
import com.mendixnative.NativeMxEncryptionSpec

@ReactModule(name = MxEncryptionModule.NAME)
class MxEncryptionModule(reactContext: ReactApplicationContext) :
    NativeMxEncryptionSpec(reactContext) {

  private val encryptedStorage = MendixEncryptedStorageModule(reactContext)

  override fun getName(): String = NAME

  override fun setItem(key: String, value: String, promise: Promise) {
    encryptedStorage.setItem(key, value, promise)
  }

  override fun getItem(key: String, promise: Promise) {
    encryptedStorage.getItem(key, promise)
  }

  override fun removeItem(key: String, promise: Promise) {
    encryptedStorage.removeItem(key, promise)
  }

  override fun clear(promise: Promise) {
    encryptedStorage.clear(promise)
  }

  override fun isEncrypted(): Boolean {
    return encryptedStorage.isEncrypted
  }

  companion object {
    const val NAME = "MxEncryption"
  }
}
