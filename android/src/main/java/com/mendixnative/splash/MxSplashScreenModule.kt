package com.mendixnative.splash

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.annotations.ReactModule
import com.mendix.mendixnative.react.splash.MendixSplashScreenModule
import com.mendix.mendixnative.react.splash.MendixSplashScreenPresenter
import com.mendixnative.NativeMxSplashScreenSpec

@ReactModule(name = MxSplashScreenModule.NAME)
class MxSplashScreenModule(reactContext: ReactApplicationContext) :
    NativeMxSplashScreenSpec(reactContext) {

  private val splashScreenModule = MendixSplashScreenModule(reactContext)

  // Presenter is injected by MendixNativePackage
  var presenter: MendixSplashScreenPresenter? = null

  override fun getName(): String = NAME

  override fun show() {
    splashScreenModule.show(presenter)
  }

  override fun hide() {
    splashScreenModule.hide(presenter)
  }

  companion object {
    const val NAME = "MxSplashScreen"
  }
}
