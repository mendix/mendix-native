package com.mendix.mendixnative.react.splash

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeMap

class MendixSplashScreenModule(val reactContext: ReactApplicationContext) {

  fun show(presenter: MendixSplashScreenPresenter?) = reactContext.currentActivity?.let {
    presenter?.show(it)
  }

  fun hide(presenter: MendixSplashScreenPresenter?) = reactContext.currentActivity?.let {
    presenter?.hide(it)
  }

  fun getConstants(): WritableMap {
    return WritableNativeMap()
  }
}
