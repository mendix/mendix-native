package com.mendix.mendixnative.activity

import android.os.Bundle
import android.view.KeyEvent
import android.view.MotionEvent
import com.facebook.react.ReactActivity
import com.facebook.react.ReactActivityDelegate
import com.facebook.react.bridge.ReactContext
import com.facebook.react.devsupport.interfaces.DevSupportManager
import com.mendix.mendixnative.DevAppMenuHandler
import com.mendix.mendixnative.MendixApplication
import com.mendix.mendixnative.MendixInitializer
import com.mendix.mendixnative.react.MendixApp
import com.mendix.mendixnative.react.splash.MendixSplashScreenPresenter
import com.mendix.mendixnative.util.MendixBackwardsCompatUtility

open class MendixReactActivity : ReactActivity(), DevAppMenuHandler, LaunchScreenHandler {

  @JvmField
  protected var mendixApp: MendixApp? = null

  private lateinit var mendixInitializer: MendixInitializer
  private var splashScreenPresenter: MendixSplashScreenPresenter? =
    (application as? MendixApplication)?.createSplashScreenPresenter()

  override fun onCreate(savedInstanceState: Bundle?) {
    mendixApp = mendixApp
      ?: intent.getSerializableExtra(MENDIX_APP_INTENT_KEY) as? MendixApp
        ?: throw IllegalStateException("MendixApp configuration can't be null")
    val mendixApplication = application as? MendixApplication
      ?: throw ClassCastException("Application needs to implement MendixApplication")

    mendixInitializer =
      MendixInitializer(this, reactHost, reactNativeHost, mendixApplication.useDeveloperSupport)
    mendixInitializer.onCreate(mendixApp!!, this, intent.getBooleanExtra(CLEAR_DATA, false))

    super.onCreate(null)
  }

  override fun onDestroy() {
    mendixInitializer.onDestroy()
    super.onDestroy()
  }

  override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
    return if (mendixInitializer.dispatchTouchEvent(ev)) {
      true
    } else super.dispatchTouchEvent(ev)
  }

  override fun getMainComponentName(): String? {
    return MAIN_COMPONENT_NAME
  }

  override fun showDevAppMenu() {
    currentDevSupportManager?.showDevOptionsDialog();
  }

  private val currentReactContext: ReactContext?
    get() = if (reactNativeHost.hasInstance()) reactInstanceManager.currentReactContext else null

  val currentDevSupportManager: DevSupportManager?
    get() = reactHost.devSupportManager

  override fun createReactActivityDelegate(): ReactActivityDelegate {
    return object : ReactActivityDelegate(this, mainComponentName) {
      override fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean {
        if (keyCode == KeyEvent.KEYCODE_MENU) {
          showDevAppMenu()
          return true
        }
        return super.onKeyUp(keyCode, event)
      }
    }
  }

  override fun showLaunchScreen() {
    if (!MendixBackwardsCompatUtility.getInstance().unsupportedFeatures.hideSplashScreenInClient && splashScreenPresenter != null) {
      splashScreenPresenter?.show(this)
    }
  }

  override fun hideLaunchScreen() {
    if (splashScreenPresenter != null) {
      splashScreenPresenter?.hide(this)
    }
  }

  companion object {
    const val MAIN_COMPONENT_NAME = "App"
    const val MENDIX_APP_INTENT_KEY = "mendixAppIntentKey"
    const val CLEAR_DATA = "clearData"
  }
}

interface LaunchScreenHandler {
  fun showLaunchScreen()
  fun hideLaunchScreen()
}

