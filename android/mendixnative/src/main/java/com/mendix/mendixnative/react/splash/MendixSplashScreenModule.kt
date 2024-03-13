package com.mendix.mendixnative.react.splash

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

class MendixSplashScreenModule(private val presenter: MendixSplashScreenPresenter, reactContext: ReactApplicationContext?) : ReactContextBaseJavaModule(reactContext!!) {
    override fun getName() = "MendixSplashScreen"

    @ReactMethod
    fun show() = currentActivity?.let {
        presenter.show(it)
    }

    @ReactMethod
    fun hide() = currentActivity?.let {
        presenter.hide(it)
    }
}
