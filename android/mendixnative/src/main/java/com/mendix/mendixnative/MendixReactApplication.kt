package com.mendix.mendixnative

import android.app.Application
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactPackage
import com.facebook.react.devsupport.interfaces.RedBoxHandler
import com.facebook.soloader.SoLoader
import com.mendix.mendixnative.error.ErrorHandler
import com.mendix.mendixnative.error.ErrorHandlerFactory
import com.mendix.mendixnative.error.mapErrorHandlerToRedBox
import com.mendix.mendixnative.handler.DummyErrorHandler
import com.mendix.mendixnative.react.MendixPackage
import com.mendix.mendixnative.react.ota.OtaJSBundleUrlProvider
import com.mendix.mendixnative.react.splash.MendixSplashScreenPresenter
import com.mendix.mendixnative.util.ResourceReader
import com.microsoft.codepush.react.CodePush
import java.util.*

abstract class MendixReactApplication : Application(), MendixApplication, ErrorHandlerFactory {
    private val appSessionId = "" + Math.random() * 1000 + Date().time
    override fun getAppSessionId(): String = appSessionId

    private var codePushKey: String? = null
    private var redBoxHandler = mapErrorHandlerToRedBox(createErrorHandler())
    private var splashScreenPresenter = createSplashScreenPresenter()
    private var jsBundleFileProvider: JSBundleFileProvider? = jsBundleProvider
    private var reactNativeHost: ReactNativeHost = object : ReactNativeHost(this) {
        override fun getUseDeveloperSupport(): Boolean {
            return this@MendixReactApplication.useDeveloperSupport
        }

        override fun getPackages(): List<ReactPackage> {
            val packages: MutableList<ReactPackage> = ArrayList()
            packages.add(MendixPackage(splashScreenPresenter))
            packages.addAll(this@MendixReactApplication.packages)
            return packages
        }

        override fun getJSBundleFile(): String? {
            return this@MendixReactApplication.jsBundleFile
        }

        override fun getJSMainModuleName(): String {
            return "index"
        }

        override fun getBundleAssetName(): String? {
            return super.getBundleAssetName()
        }

        override fun getRedBoxHandler(): RedBoxHandler? {
            return this@MendixReactApplication.redBoxHandler
        }
    }

    override fun onCreate() {
        super.onCreate()
        SoLoader.init(this,  /* native exopackage */false)
        codePushKey = ResourceReader.readString(this, "code_push_key")
    }

    override fun getCodePushKey(): String {
        return codePushKey!!
    }

    override fun getJSBundleFile(): String? {
        // Check for Native OTA
        OtaJSBundleUrlProvider().getJSBundleFile(this)?.let {
            return it
        }

        // Check for CodePush
        if (useCodePush()) return CodePush.getJSBundleFile()

        // Fallback to bundled bundle
        return if (jsBundleFileProvider != null) jsBundleFileProvider!!.getJSBundleFile(this) else null
    }

    private fun useCodePush(): Boolean {
        return codePushKey!!.isNotEmpty()
    }

    abstract override fun getUseDeveloperSupport(): Boolean
    abstract override fun getPackages(): List<ReactPackage>
    override fun createSplashScreenPresenter(): MendixSplashScreenPresenter? {
        return null
    }

    override fun createErrorHandler(): ErrorHandler {
        return DummyErrorHandler()
    }

    override fun getReactNativeHost(): ReactNativeHost {
        return reactNativeHost
    }

    open val jsBundleProvider: JSBundleFileProvider?
        get() = null
}
