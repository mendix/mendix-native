package com.mendix.mendixnative

import android.app.Application
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactPackage
import com.facebook.react.bridge.JSBundleLoader
import com.facebook.react.bridge.JSBundleLoaderDelegate
import com.facebook.react.common.annotations.UnstableReactNativeAPI
import com.facebook.react.defaults.DefaultComponentsRegistry
import com.facebook.react.defaults.DefaultReactHostDelegate
import com.facebook.react.defaults.DefaultTurboModuleManagerDelegate
import com.facebook.react.devsupport.interfaces.RedBoxHandler
import com.facebook.react.fabric.ComponentFactory
import com.facebook.react.runtime.ReactHostImpl
import com.facebook.react.runtime.hermes.HermesInstance
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

  /**
   * Build the [ReactHost] ourselves instead of using [DefaultReactHost.getDefaultReactHost],
   * because that factory evaluates [ReactNativeHost.getJSBundleFile] once at creation time and
   * bakes the result into a fixed [JSBundleLoader]. After an OTA update deploys a new bundle,
   * a subsequent [ReactHost.reload] would still load the stale bundle.
   *
   * By providing a **dynamic** [JSBundleLoader] whose [JSBundleLoader.loadScript] calls
   * [getJSBundleFile] on every invocation, each reload picks up the latest bundle path —
   * whether it comes from OTA, a custom [JSBundleFileProvider], or the default asset bundle.
   */
  @OptIn(UnstableReactNativeAPI::class)
  override val reactHost: ReactHost by lazy {
    val dynamicBundleLoader = object : JSBundleLoader() {
      override fun loadScript(delegate: JSBundleLoaderDelegate): String {
        val bundle = jsBundleFile
        if (bundle != null) {
          if (bundle.startsWith("assets://")) {
            delegate.loadScriptFromAssets(assets, bundle, true)
          } else {
            delegate.loadScriptFromFile(bundle, bundle, false)
          }
          return bundle
        }
        val defaultBundle = "assets://index.android.bundle"
        delegate.loadScriptFromAssets(assets, defaultBundle, true)
        return defaultBundle
      }
    }

    val hostPackages: MutableList<ReactPackage> = ArrayList(this@MendixReactApplication.packages)
    applyInternalPackageAugmentations(hostPackages)

    val delegate = DefaultReactHostDelegate(
      jsMainModulePath = "index",
      jsBundleLoader = dynamicBundleLoader,
      reactPackages = hostPackages,
      jsRuntimeFactory = HermesInstance(),
      turboModuleManagerDelegateBuilder = DefaultTurboModuleManagerDelegate.Builder(),
    )
    val componentFactory = ComponentFactory()
    DefaultComponentsRegistry.register(componentFactory)
    ReactHostImpl(
      applicationContext,
      delegate,
      componentFactory,
      true /* allowPackagerServerAccess */,
      useDeveloperSupport,
    )
  }

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
