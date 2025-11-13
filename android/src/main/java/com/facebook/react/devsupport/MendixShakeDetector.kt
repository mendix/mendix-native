package com.facebook.react.devsupport

import android.content.Context
import android.hardware.SensorManager
import com.facebook.react.common.ShakeDetector
import com.facebook.react.devsupport.interfaces.DevSupportManager
import com.mendix.mendixnative.util.ReflectionUtils

const val SHAKE_DETECTECTOR_VAR = "mShakeDetector"

fun makeShakeDetector(applicationContext: Context, onShake: () -> Unit): ShakeDetector {
  val shakeDetector = ShakeDetector(onShake)

  shakeDetector.start(applicationContext.getSystemService(Context.SENSOR_SERVICE) as SensorManager)
  return shakeDetector
}

fun attachMendixSupportManagerShakeDetector(
  shakeDetector: ShakeDetector,
  devSupportManager: DevSupportManager?
): Unit = devSupportManager.let { supportManager ->
  val devShakeDetector =
    ReflectionUtils.getFieldOfSuperclass<ShakeDetector>(supportManager, SHAKE_DETECTECTOR_VAR)
  (devShakeDetector != shakeDetector).let { devShakeDetector.stop() }
  ReflectionUtils.setFieldOfSuperclass(supportManager, SHAKE_DETECTECTOR_VAR, shakeDetector)
}
