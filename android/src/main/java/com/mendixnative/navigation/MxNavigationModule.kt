package com.mendixnative.navigation

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.annotations.ReactModule
import com.mendix.mendixnative.react.NavigationModeModule
import com.mendixnative.NativeMxNavigationSpec

@ReactModule(name = MxNavigationModule.NAME)
class MxNavigationModule(reactContext: ReactApplicationContext) :
    NativeMxNavigationSpec(reactContext) {

  private val navigationMode = NavigationModeModule(reactContext)

  override fun getName(): String = NAME

  override fun isNavigationBarActive(): Boolean {
    return navigationMode.isNavigationBarActive()
  }

  override fun getNavigationBarHeight(): Double {
    return navigationMode.getNavigationBarHeight()
  }

  companion object {
    const val NAME = "MxNavigation"
  }
}
