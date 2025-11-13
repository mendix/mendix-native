package com.mendixnative

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import com.mendix.mendixnative.react.splash.MendixSplashScreenPresenter
import java.util.HashMap

class MendixNativePackage : BaseReactPackage() {

  var splashScreenPresenter: MendixSplashScreenPresenter? = null

  override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
    return if (name == MendixNativeModule.NAME) {
      val module = MendixNativeModule(reactContext)
      module.presenter = splashScreenPresenter
      return module
    } else {
      null
    }
  }

  override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
    return ReactModuleInfoProvider {
      val moduleInfos: MutableMap<String, ReactModuleInfo> = HashMap()
      moduleInfos[MendixNativeModule.NAME] = ReactModuleInfo(
        MendixNativeModule.NAME,
        MendixNativeModule.NAME,
        false,  // canOverrideExistingModule
        false,  // needsEagerInit
        false,  // isCxxModule
        true // isTurboModule
      )
      moduleInfos
    }
  }
}
