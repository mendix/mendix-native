package com.mendixnative

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import com.mendix.mendixnative.react.splash.MendixSplashScreenPresenter
import com.mendixnative.configuration.MxConfigurationModule
import com.mendixnative.cookie.MxCookieModule
import com.mendixnative.download.MxDownloadModule
import com.mendixnative.encryption.MxEncryptionModule
import com.mendixnative.error.MxErrorModule
import com.mendixnative.fs.MxFileSystemModule
import com.mendixnative.navigation.MxNavigationModule
import com.mendixnative.ota.MxOtaModule
import com.mendixnative.reload.MxReloadModule
import com.mendixnative.splash.MxSplashScreenModule
import java.util.HashMap

class MendixNativePackage : BaseReactPackage() {

  var splashScreenPresenter: MendixSplashScreenPresenter? = null

  override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
    return when (name) {
      MxEncryptionModule.NAME -> MxEncryptionModule(reactContext)
      MxSplashScreenModule.NAME -> {
        val module = MxSplashScreenModule(reactContext)
        module.presenter = splashScreenPresenter
        module
      }
      MxFileSystemModule.NAME -> MxFileSystemModule(reactContext)
      MxOtaModule.NAME -> MxOtaModule(reactContext)
      MxDownloadModule.NAME -> MxDownloadModule(reactContext)
      MxReloadModule.NAME -> MxReloadModule(reactContext)
      MxConfigurationModule.NAME -> MxConfigurationModule(reactContext)
      MxCookieModule.NAME -> MxCookieModule(reactContext)
      MxErrorModule.NAME -> MxErrorModule(reactContext)
      MxNavigationModule.NAME -> MxNavigationModule(reactContext)
      else -> null
    }
  }

  override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
    return ReactModuleInfoProvider {
      val moduleInfos: MutableMap<String, ReactModuleInfo> = HashMap()
      listOf(
        MxEncryptionModule.NAME,
        MxSplashScreenModule.NAME,
        MxFileSystemModule.NAME,
        MxOtaModule.NAME,
        MxDownloadModule.NAME,
        MxReloadModule.NAME,
        MxConfigurationModule.NAME,
        MxCookieModule.NAME,
        MxErrorModule.NAME,
        MxNavigationModule.NAME
      ).forEach {
        moduleInfos[it] = ReactModuleInfo(
          name = it,
          className = it,
          canOverrideExistingModule = false,
          needsEagerInit = false,
          isCxxModule = false,
          isTurboModule = true
        )
      }
      moduleInfos
    }
  }
}
