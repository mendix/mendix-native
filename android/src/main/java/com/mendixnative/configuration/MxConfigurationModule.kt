package com.mendixnative.configuration

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.module.annotations.ReactModule
import com.mendix.mendixnative.react.MxConfiguration
import com.mendixnative.NativeMxConfigurationSpec

@ReactModule(name = MxConfigurationModule.NAME)
class MxConfigurationModule(reactContext: ReactApplicationContext) :
    NativeMxConfigurationSpec(reactContext) {

  private val configuration = MxConfiguration(reactContext)

  override fun getName(): String = NAME

  override fun getConfig(): WritableMap? {
    return configuration.getConstants()
  }

  companion object {
    const val NAME = "MxConfiguration"
  }
}
