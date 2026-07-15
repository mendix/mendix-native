package com.mendix.mendixnative.activity

import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import com.facebook.react.ReactActivity
import com.facebook.react.ReactActivityDelegate
import com.facebook.react.devsupport.interfaces.DevSupportManager
import com.mendix.mendixnative.DevAppMenuHandler
import com.mendix.mendixnative.MendixApplication
import com.mendix.mendixnative.MendixInitializer
import com.mendix.mendixnative.react.MendixApp
import com.mendix.mendixnative.react.splash.MendixSplashScreenPresenter
import java.io.Serializable

open class MendixReactActivity : ReactActivity(), DevAppMenuHandler, LaunchScreenHandler {

  @JvmField
  protected var mendixApp: MendixApp? = null

  private lateinit var mendixInitializer: MendixInitializer
  private var splashScreenPresenter: MendixSplashScreenPresenter? =
    (application as? MendixApplication)?.createSplashScreenPresenter()

  override fun onCreate(savedInstanceState: Bundle?) {
    mendixApp = mendixApp
      ?: getSerializableData(MENDIX_APP_INTENT_KEY, MendixApp::class.java)
        ?: throw IllegalStateException("MendixApp configuration can't be null")
    val mendixApplication = application as? MendixApplication
      ?: throw ClassCastException("Application needs to implement MendixApplication")

    mendixInitializer =
      MendixInitializer(this, reactHost, mendixApplication.useDeveloperSupport)
    mendixInitializer.onCreate(mendixApp!!, intent.getBooleanExtra(CLEAR_DATA, false))

    super.onCreate(null)
  }

  inline fun <reified T : Serializable> getSerializableData(key: String?, clazz: Class<T>): T? {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      intent.getSerializableExtra<T?>(key, clazz)
    } else {
      @Suppress("DEPRECATION")
      val data = intent.getSerializableExtra(key)
      if (data is T) {
        return data
      }
      return null
    }
  }

  override fun onDestroy() {
    mendixInitializer.onDestroy()
    super.onDestroy()
  }

  override fun getMainComponentName(): String? {
    return MAIN_COMPONENT_NAME
  }

  override fun showDevAppMenu() {
    currentDevSupportManager?.showDevOptionsDialog()
  }

  val currentDevSupportManager: DevSupportManager?
    get() = reactHost.devSupportManager

  override fun createReactActivityDelegate(): ReactActivityDelegate {
    return object : ReactActivityDelegate(this, mainComponentName) {
      override fun onKeyUp(keyCode: Int, event: KeyEvent): Boolean {
        if (keyCode == KeyEvent.KEYCODE_MENU) {
          if (mendixApp?.showExtendedDevMenu == true) {
            showDevAppMenu()
          }
          return true
        }
        return super.onKeyUp(keyCode, event)
      }
    }
  }

  override fun showLaunchScreen() {
    splashScreenPresenter?.show(this)
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

