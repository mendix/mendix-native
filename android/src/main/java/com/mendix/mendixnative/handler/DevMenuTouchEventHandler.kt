package com.mendix.mendixnative.handler

import android.view.MotionEvent
import kotlin.math.abs

class DevMenuTouchEventHandler(private var listener: DevMenuTouchListener?) {
  private val targetPointerCount = 3
  private val tapTimeout = 500
  private val moveThreshold = 100f
  private var captureNextUpAction = false
  private var pointerDownX = 0f
  private var pointerDownY = 0f

  fun handle(event: MotionEvent?): Boolean {
    when (event?.actionMasked) {
      MotionEvent.ACTION_POINTER_DOWN -> onPointerDownAction(event)
      MotionEvent.ACTION_POINTER_UP -> onPointerUpAction(event)
      MotionEvent.ACTION_UP -> return onUpAction(event)
    }
    return false
  }

  private fun onPointerDownAction(event: MotionEvent) {
    captureNextUpAction = event.pointerCount == targetPointerCount
    if (captureNextUpAction) {
      pointerDownX = event.x
      pointerDownY = event.y
    }
  }

  private fun onPointerUpAction(event: MotionEvent) {
    if (event.pointerCount == targetPointerCount) {
      val deltaX = abs(pointerDownX - event.x)
      val deltaY = abs(pointerDownY - event.y)
      if (deltaX > moveThreshold || deltaY > moveThreshold) {
        captureNextUpAction = false
      }
    }
  }

  private fun onUpAction(event: MotionEvent): Boolean {
    if (!captureNextUpAction) {
      return false
    }
    val timeSinceDownAction = event.eventTime - event.downTime
    if (timeSinceDownAction < tapTimeout) {
      onTap()
    } else {
      onLongPress()
    }
    captureNextUpAction = false
    return true
  }

  private fun onTap() {
    listener?.onTap()
  }

  private fun onLongPress() {
    listener?.onLongPress()
  }

  interface DevMenuTouchListener {
    fun onTap()
    fun onLongPress()
  }

}
