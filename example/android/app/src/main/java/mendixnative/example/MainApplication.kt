package mendixnative.example

import com.facebook.react.PackageList
import com.facebook.react.ReactPackage
import com.mendix.mendixnative.MendixReactApplication
import com.mendix.mendixnative.react.splash.MendixSplashScreenPresenter
import com.mendix.mendixnative.react.MxConfiguration

class SplashScreenPresenter: MendixSplashScreenPresenter {
    override fun show(activity: android.app.Activity) {}
    override fun hide(activity: android.app.Activity) {}
}

class MainApplication : MendixReactApplication() {

  override fun onCreate() {
    super.onCreate()
    MxConfiguration.runtimeUrl = "http://10.0.2.2:8081"
  }

  override fun getUseDeveloperSupport() = BuildConfig.DEBUG
  override fun createSplashScreenPresenter() = SplashScreenPresenter()
  override fun getPackages(): List<ReactPackage> = PackageList(this).packages
  override fun getJSBundleFile(): String? = null
  override fun getAppSessionId() = ""
}
