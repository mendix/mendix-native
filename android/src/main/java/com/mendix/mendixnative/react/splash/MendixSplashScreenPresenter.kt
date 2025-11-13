package com.mendix.mendixnative.react.splash

import android.app.Activity

interface MendixSplashScreenPresenter {
  fun show(activity: Activity)
  fun hide(activity: Activity)
}
