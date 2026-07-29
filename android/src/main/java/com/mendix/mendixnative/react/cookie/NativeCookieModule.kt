package com.mendix.mendixnative.react.cookie

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.modules.network.ForwardingCookieHandler

class NativeCookieModule(val reactContext: ReactApplicationContext) {
  fun clearAll(promise: Promise) {
    ForwardingCookieHandler().clearCookies {
      promise.resolve(null)
    }
  }
}
