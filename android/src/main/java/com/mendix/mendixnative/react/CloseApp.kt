package com.mendix.mendixnative.react

import com.facebook.react.bridge.ReactContext
import com.op.sqlite.OPSQLiteModule

fun closeSqlDatabaseConnection(reactContext: ReactContext?) {
  reactContext?.typeSafeNativeModule<OPSQLiteModule>()?.closeAllConnections()
}
