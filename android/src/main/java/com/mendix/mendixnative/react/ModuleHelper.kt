package com.mendix.mendixnative.react

import android.util.Log
import com.facebook.react.ReactApplication
import com.facebook.react.ReactHost
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContext
inline fun <reified T: NativeModule> ReactContext.nativeModule(name: String): T? {
  return try {
    getNativeModule(name) as? T
  } catch (e: Exception) {
    Log.e("ModuleAccess", "Error getting module ${T::class.simpleName}", e)
    null
  }
}

inline fun <reified T: NativeModule> ReactHost.nativeModule(name: String): T? {
  return currentReactContext?.nativeModule<T>(name)
}

inline fun <reified T: NativeModule> ReactApplicationContext.nativeModule(name: String): T? {
    return (applicationContext as? ReactApplication)?.reactHost?.nativeModule<T>(name)
}
