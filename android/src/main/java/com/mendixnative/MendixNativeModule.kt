package com.mendixnative

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap
import com.facebook.react.module.annotations.ReactModule
import com.mendix.mendixnative.encryption.MendixEncryptedStorageModule
import com.mendix.mendixnative.react.MxConfiguration
import com.mendix.mendixnative.react.NativeErrorHandler
import com.mendix.mendixnative.react.NativeReloadHandler
import com.mendix.mendixnative.react.cookie.NativeCookieModule
import com.mendix.mendixnative.react.download.NativeDownloadModule
import com.mendix.mendixnative.react.fs.NativeFsModule
import com.mendix.mendixnative.react.ota.NativeOtaModule
import com.mendix.mendixnative.react.splash.MendixSplashScreenModule
import com.mendix.mendixnative.react.splash.MendixSplashScreenPresenter

@ReactModule(name = MendixNativeModule.NAME)
class MendixNativeModule(reactContext: ReactApplicationContext) : NativeMendixNativeSpec(reactContext) {

  var presenter: MendixSplashScreenPresenter? = null

  override fun getName(): String {
    return NAME
  }

  override fun encryptedStorageSetItem(key: String, value: String, promise: Promise) {
    MendixEncryptedStorageModule(reactApplicationContext).setItem(key, value, promise)
  }

  override fun encryptedStorageGetItem(key: String, promise: Promise) {
    MendixEncryptedStorageModule(reactApplicationContext).getItem(key, promise)
  }

  override fun encryptedStorageRemoveItem(key: String, promise: Promise) {
    MendixEncryptedStorageModule(reactApplicationContext).removeItem(key, promise)
  }

  override fun encryptedStorageClear(promise: Promise) {
    MendixEncryptedStorageModule(reactApplicationContext).clear(promise)
  }

  override fun encryptedStorageIsEncrypted(): Boolean {
    return MendixEncryptedStorageModule(reactApplicationContext).isEncrypted
  }

  override fun splashScreenShow() {
    MendixSplashScreenModule(reactApplicationContext).show(presenter)
  }

  override fun splashScreenHide() {
    MendixSplashScreenModule(reactApplicationContext).hide(presenter)
  }

  override fun cookieClearAll(promise: Promise) {
    NativeCookieModule(reactApplicationContext).clearAll(promise)
  }

  override fun reloadHandlerReload(promise: Promise) {
    NativeReloadHandler(reactApplicationContext).reload()
    promise.resolve(null)
  }

  fun reloadClientWithState() {
    emitOnReloadWithState()
  }

  override fun reloadHandlerExitApp(promise: Promise) {
    NativeReloadHandler(reactApplicationContext).exitApp()
    promise.resolve(null)
  }

  override fun downloadHandlerDownload(
    url: String,
    downloadPath: String,
    config: ReadableMap,
    promise: Promise
  ) {
    NativeDownloadModule(reactApplicationContext).download(
      url, downloadPath, config, promise
    )
  }

  override fun mxConfigurationGetConfig(): WritableMap? {
    return MxConfiguration(reactApplicationContext).getConstants()
  }

  override fun otaDownload(
    config: ReadableMap,
    promise: Promise
  ) {
    NativeOtaModule(reactApplicationContext).download(config, promise)
  }

  override fun otaDeploy(
    config: ReadableMap,
    promise: Promise
  ) {
    NativeOtaModule(reactApplicationContext).deploy(config, promise)
  }

  override fun fsSetEncryptionEnabled(enabled: Boolean) {
    NativeFsModule(reactApplicationContext).setEncryptionEnabled(enabled)
  }

  override fun fsSave(
    blob: ReadableMap,
    filePath: String,
    promise: Promise
  ) {
    NativeFsModule(reactApplicationContext).save(blob, filePath, promise)
  }

  override fun fsRead(filePath: String, promise: Promise) {
    NativeFsModule(reactApplicationContext).read(filePath, promise)
  }

  override fun fsMove(
    filePath: String,
    newPath: String,
    promise: Promise
  ) {
    NativeFsModule(reactApplicationContext).move(filePath, newPath, promise)
  }

  override fun fsRemove(filePath: String, promise: Promise) {
    NativeFsModule(reactApplicationContext).remove(filePath, promise)
  }

  override fun fsList(dirPath: String, promise: Promise) {
    NativeFsModule(reactApplicationContext).list(dirPath, promise)
  }

  override fun fsReadAsDataURL(
    filePath: String,
    promise: Promise
  ) {
    NativeFsModule(reactApplicationContext).readAsDataURL(filePath, promise)
  }

  override fun fsReadAsText(filePath: String, promise: Promise) {
    NativeFsModule(reactApplicationContext).readAsText(filePath, promise)
  }

  override fun fsFileExists(filePath: String, promise: Promise) {
    NativeFsModule(reactApplicationContext).fileExists(filePath, promise)
  }

  override fun fsWriteJson(
    data: ReadableMap,
    filepath: String,
    promise: Promise
  ) {
    NativeFsModule(reactApplicationContext).writeJson(data, filepath, promise)
  }

  override fun fsReadJson(filepath: String, promise: Promise) {
    NativeFsModule(reactApplicationContext).readJson(filepath, promise)
  }

  override fun fsConstants(): WritableMap? {
    return NativeFsModule(reactApplicationContext).getConstants()
  }

  override fun errorHandlerHandle(message: String, stackTrace: ReadableArray) {
    NativeErrorHandler(reactApplicationContext).handle(message, stackTrace)
  }

  companion object {
    const val NAME = "MendixNative"
  }
}
