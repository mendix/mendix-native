package com.mendixnative.cookie

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.annotations.ReactModule
import com.mendix.mendixnative.react.cookie.NativeCookieModule
import com.mendixnative.NativeMxCookieSpec

@ReactModule(name = MxCookieModule.NAME)
class MxCookieModule(reactContext: ReactApplicationContext) :
    NativeMxCookieSpec(reactContext) {

  private val cookieModule = NativeCookieModule(reactContext)

  override fun getName(): String = NAME

  override fun clearAll(promise: Promise) {
    cookieModule.clearAll(promise)
  }

  companion object {
    const val NAME = "MxCookie"
  }
}
