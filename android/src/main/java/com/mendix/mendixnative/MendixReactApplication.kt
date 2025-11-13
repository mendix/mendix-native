package com.mendix.mendixnative

import android.app.Application
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactPackage
import com.facebook.react.devsupport.interfaces.RedBoxHandler
import com.facebook.react.soloader.OpenSourceMergedSoMapping
import com.facebook.soloader.SoLoader
import com.mendix.mendixnative.error.ErrorHandler
import com.mendix.mendixnative.error.ErrorHandlerFactory
import com.mendix.mendixnative.error.mapErrorHandlerToRedBox
import com.mendix.mendixnative.handler.DummyErrorHandler
import com.mendix.mendixnative.react.ota.OtaJSBundleUrlProvider
import com.mendix.mendixnative.react.splash.MendixSplashScreenPresenter
import com.mendixnative.MendixNativePackage
import java.util.*
import com.facebook.react.defaults.DefaultNewArchitectureEntryPoint.load
import com.facebook.react.defaults.DefaultReactHost.getDefaultReactHost

import com.facebook.react.defaults.DefaultReactNativeHost

abstract class MendixReactApplication : Application(), MendixApplication, ErrorHandlerFactory {
  private val appSessionId = "" + Math.random() * 1000 + Date().time
  override fun getAppSessionId(): String = appSessionId

  // Lazily create RedBox handler only in dev. In release builds this stays null.
  private val redBoxHandler: RedBoxHandler? by lazy {
    if (useDeveloperSupport) mapErrorHandlerToRedBox(createErrorHandler()) else null
  }

  // Lazily obtain splash presenter so subclass overrides are respected.
  private val splashScreenPresenter by lazy { createSplashScreenPresenter() }

  private var jsBundleFileProvider: JSBundleFileProvider? = jsBundleProvider

  override var reactNativeHost: ReactNativeHost = object : DefaultReactNativeHost(this) {
    override fun getUseDeveloperSupport(): Boolean = this@MendixReactApplication.useDeveloperSupport

    override fun getPackages(): List<ReactPackage> {
      val pkgs: MutableList<ReactPackage> = ArrayList()
      // Use the packages provided by the concrete Application subclass.
      pkgs.addAll(this@MendixReactApplication.packages)
      // Inject splashScreenPresenter into any MendixNativePackage instances without creating duplicates.
      applyInternalPackageAugmentations(pkgs)
      return pkgs
    }

    override fun getJSBundleFile(): String? = this@MendixReactApplication.jsBundleFile
    override fun getJSMainModuleName(): String = "index"
    override fun getBundleAssetName(): String? = super.getBundleAssetName()
    override fun getRedBoxHandler(): RedBoxHandler? = null

    // Hermes & New Arch flags; Hermes executor will be picked automatically when isHermesEnabled is true.
    override val isNewArchEnabled: Boolean = true
    override val isHermesEnabled: Boolean = true
  }

  override val reactHost: ReactHost
    get() = getDefaultReactHost(applicationContext, reactNativeHost)

  /**
   * Apply internal augmentations to packages (e.g., attach presenters) without instantiating
   * duplicate packages that would cause "duplicate module name" initialization errors.
   */
  private fun applyInternalPackageAugmentations(packages: MutableList<ReactPackage>) {
    packages.filterIsInstance<MendixNativePackage>().forEach { pkg ->
      // Only set if not already set to avoid overwriting from user code.
      if (pkg.splashScreenPresenter == null) {
        pkg.splashScreenPresenter = splashScreenPresenter
      }
    }
  }

  override fun onCreate() {
    super.onCreate()
    SoLoader.init(this, OpenSourceMergedSoMapping)
    // Only load the New Architecture entry point when enabled (always true here, but guarded for safety).
    if (reactNativeHost is DefaultReactNativeHost) {
      load()
    }
  }

  override fun getJSBundleFile(): String? {
    // Check for Native OTA
    OtaJSBundleUrlProvider().getJSBundleFile(this)?.let {
      return it
    }

    // Fallback to bundled bundle
    return if (jsBundleFileProvider != null) jsBundleFileProvider!!.getJSBundleFile(this) else null
  }

  abstract override fun getUseDeveloperSupport(): Boolean
  abstract override fun getPackages(): List<ReactPackage>
  override fun createSplashScreenPresenter(): MendixSplashScreenPresenter? {
    return null
  }

  override fun createErrorHandler(): ErrorHandler {
    return DummyErrorHandler()
  }

  open val jsBundleProvider: JSBundleFileProvider?
    get() = null
}
