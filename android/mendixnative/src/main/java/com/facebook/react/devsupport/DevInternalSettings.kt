package com.facebook.react.devsupport

import com.mendix.mendixnative.activity.MendixReactActivity
import com.mendix.mendixnative.util.ReflectionUtils

fun getDevInternalSettings(activity: MendixReactActivity): DevInternalSettings? =
        (activity.currentDevSupportManager as? DevSupportManagerBase)?.let {
            return ReflectionUtils.getField<DevInternalSettings>(it, "mDevSettings")
        }
