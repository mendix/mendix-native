package com.facebook.react.devsupport

import android.content.Context
import android.hardware.SensorManager
import com.facebook.react.common.ShakeDetector
import com.facebook.react.devsupport.interfaces.DevSupportManager
import com.mendix.mendixnative.util.ReflectionUtils

const val SHAKE_DETECTECTOR_VAR = "mShakeDetector"
const val SHAKE_DETECTOR_VAR = "shakeDetector"

fun makeShakeDetector(applicationContext: Context, onShake: () -> Unit): ShakeDetector {
  val shakeDetector = ShakeDetector(onShake)

  shakeDetector.start(applicationContext.getSystemService(Context.SENSOR_SERVICE) as SensorManager)
  return shakeDetector
}

fun attachMendixSupportManagerShakeDetector(
  shakeDetector: ShakeDetector,
  devSupportManager: DevSupportManager?
) {
  val supportManager = devSupportManager ?: return

  try {
    val devShakeDetector =
      ReflectionUtils.getFieldOfSuperclass<ShakeDetector>(
        supportManager,
        SHAKE_DETECTECTOR_VAR,
        SHAKE_DETECTOR_VAR
      )

    if (devShakeDetector !== shakeDetector) {
      devShakeDetector.stop()
    }

    ReflectionUtils.setFieldOfSuperclass(
      supportManager,
      shakeDetector,
      SHAKE_DETECTECTOR_VAR,
      SHAKE_DETECTOR_VAR
    )
  } catch (_: RuntimeException) {
    // React Native internals changed; keep the Mendix detector active without replacing RN's.
  }
}
