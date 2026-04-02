package com.mendixnative.ota

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.mendix.mendixnative.react.ota.NativeOtaModule
import com.mendixnative.NativeMxOtaSpec

@ReactModule(name = MxOtaModule.NAME)
class MxOtaModule(reactContext: ReactApplicationContext) :
    NativeMxOtaSpec(reactContext) {

  private val otaModule = NativeOtaModule(reactContext)

  override fun getName(): String = NAME

  override fun download(config: ReadableMap, promise: Promise) {
    otaModule.download(config, promise)
  }

  override fun deploy(config: ReadableMap, promise: Promise) {
    otaModule.deploy(config, promise)
  }

  companion object {
    const val NAME = "MxOta"
  }
}
