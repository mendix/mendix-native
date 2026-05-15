package com.mendixnative.error

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.module.annotations.ReactModule
import com.mendix.mendixnative.react.NativeErrorHandler
import com.mendixnative.NativeMxErrorSpec

@ReactModule(name = MxErrorModule.NAME)
class MxErrorModule(reactContext: ReactApplicationContext) :
    NativeMxErrorSpec(reactContext) {

  private val errorHandler = NativeErrorHandler(reactContext)

  override fun getName(): String = NAME

  override fun handle(message: String, stackTrace: ReadableArray) {
    errorHandler.handle(message, stackTrace)
  }

  companion object {
    const val NAME = "MxError"
  }
}
