package com.mendix.mendixnative.util

import android.os.Handler
import android.view.KeyEvent
import android.view.View
import android.widget.EditText

class MendixDoubleTapRecognizer {
    private var mDoRefresh = false
    private val DOUBLE_TAP_DELAY: Long = 200

    fun didDoubleTapBacktick(keyCode: Int, view: View?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_GRAVE && view !is EditText) {
            if (mDoRefresh) {
                mDoRefresh = false
                return true
            } else {
                mDoRefresh = true
                Handler()
                        .postDelayed(
                                { mDoRefresh = false },
                                DOUBLE_TAP_DELAY)
            }
        }
        return false
    }
}
