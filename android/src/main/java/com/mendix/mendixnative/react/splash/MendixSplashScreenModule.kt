package com.mendix.mendixnative.react.splash

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeMap
import com.mendix.mendixnative.react.runOnUiThread

class MendixSplashScreenModule(val reactContext: ReactApplicationContext) {

  // Called from the native modules thread; presenters touch views, so hop to the UI thread.
  fun show(presenter: MendixSplashScreenPresenter?) {
    runOnUiThread {
      reactContext.currentActivity?.let { presenter?.show(it) }
    }
  }

  fun hide(presenter: MendixSplashScreenPresenter?) {
    runOnUiThread {
      reactContext.currentActivity?.let { presenter?.hide(it) }
    }
  }

  fun getConstants(): WritableMap {
    return WritableNativeMap()
  }
}
