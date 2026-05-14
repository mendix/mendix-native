package com.facebook.react.devsupport

import com.facebook.react.modules.debug.interfaces.DeveloperSettings
import com.mendix.mendixnative.activity.MendixReactActivity
import com.mendix.mendixnative.util.ReflectionUtils

fun getDevInternalSettings(activity: MendixReactActivity): DeveloperSettings? =
  (activity.currentDevSupportManager as? DevSupportManagerBase)?.let {
    return ReflectionUtils.getField<DeveloperSettings>(it, "mDevSettings")
  }
