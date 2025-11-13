package com.mendix.mendixnative.react

import android.os.Handler
import android.os.Looper

fun runOnUiThread(cb: () -> Unit) = Handler(Looper.getMainLooper()).post(cb)
