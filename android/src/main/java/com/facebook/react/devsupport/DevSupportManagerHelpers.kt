package com.facebook.react.devsupport

import com.facebook.react.devsupport.interfaces.DevBundleDownloadListener
import com.facebook.react.devsupport.interfaces.DevSupportManager
import com.mendix.mendixnative.util.ReflectionUtils

fun setBundleDownloadListener(
  devSupportManager: DevSupportManager?,
  listener: DevBundleDownloadListener
) {
  devSupportManager?.apply {
    ReflectionUtils.setFieldOfSuperclass(this, "mBundleDownloadListener", listener)
  }
}

fun overrideDevLoadingViewController(
  devSupportManager: DevSupportManager,
  devLoadingViewController: DefaultDevLoadingViewImplementation
) {
  devSupportManager.apply {
    ReflectionUtils.setFieldOfSuperclass(this, "mDevLoadingViewManager", devLoadingViewController)
  }
}
