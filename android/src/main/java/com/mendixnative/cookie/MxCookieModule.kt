package com.mendixnative.cookie

import com.facebook.react.bridge.Arguments
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

  // The following methods are iOS-only (keychain / SessionCookieStore).
  // They are no-ops on Android so the TurboModule spec is satisfied.

  override fun persistTestCookies(count: Double, valueSize: Double, promise: Promise) {
    promise.resolve(null)
  }

  override fun restoreSessionCookies(promise: Promise) {
    promise.resolve(Arguments.createArray())
  }

  override fun getKeychainChunkCount(promise: Promise) {
    promise.resolve(0.0)
  }

  companion object {
    const val NAME = "MxCookie"
  }
}
