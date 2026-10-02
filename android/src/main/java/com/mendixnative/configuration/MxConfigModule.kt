package com.mendixnative.configuration

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.annotations.ReactModule
import com.mendix.mendixnative.react.MxConfiguration
import com.mendixnative.NativeMxConfigSpec

@ReactModule(name = MxConfigModule.NAME)
class MxConfigModule(reactContext: ReactApplicationContext) :
    NativeMxConfigSpec(reactContext) {

  private val configuration = MxConfiguration(reactContext)

  override fun getName(): String = NAME

  override fun getTypedExportedConstants(): Map<String, Any?> {
    return configuration.getConstants()
  }

  companion object {
    const val NAME = "MxConfig"
  }
}
