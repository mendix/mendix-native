package com.mendix.mendixnative.react

import android.annotation.SuppressLint
import android.util.Log
import com.facebook.react.ReactApplication
import com.facebook.react.ReactNativeHost
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContext

inline fun <reified T: NativeModule> ReactContext.typeSafeNativeModule(): T? {
  return try {
    getNativeModule(T::class.java)
  } catch (e: Exception) {
    Log.e("ModuleAccess", "Error getting module ${T::class.simpleName}", e)
    null
  }
}

inline fun <reified T: NativeModule> ReactNativeHost.typeSafeNativeModule(): T? {
  return reactContext()?.typeSafeNativeModule<T>()
}

fun ReactNativeHost.reactContext(): ReactContext? {
  return reactInstanceManager.currentReactContext
}

fun ReactNativeHost.reactApplicationContext(): ReactApplicationContext? {
  val context = reactContext()
  if (context is ReactApplicationContext) {
    return context
  }
  return null
}
