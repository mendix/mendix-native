package com.mendixnative.reload

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.annotations.ReactModule
import com.mendix.mendixnative.react.NativeReloadHandler
import com.mendixnative.NativeMxReloadSpec

@ReactModule(name = MxReloadModule.NAME)
class MxReloadModule(reactContext: ReactApplicationContext) :
    NativeMxReloadSpec(reactContext) {

  private val reloadHandler = NativeReloadHandler(reactContext)

  override fun getName(): String = NAME

  override fun reload(promise: Promise) {
    reloadHandler.reload()
    promise.resolve(null)
  }

  override fun exitApp(promise: Promise) {
    reloadHandler.exitApp()
    promise.resolve(null)
  }

  companion object {
    const val NAME = "MxReload"
  }
}
