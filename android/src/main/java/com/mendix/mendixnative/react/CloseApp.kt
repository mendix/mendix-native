package com.mendix.mendixnative.react

import android.util.Log
import com.facebook.react.bridge.ReactContext
import com.op.sqlite.OPSQLiteModule

/**
 * Closes all SQLite database connections.
 *
 * This is called during app shutdown to gracefully close database connections.
 */
fun closeSqlDatabaseConnection(reactContext: ReactContext?) {
  val opSQLiteModule = reactContext?.nativeModule<OPSQLiteModule>(OPSQLiteModule.NAME)
  if (opSQLiteModule != null) {
    try {
      opSQLiteModule.closeAllConnections()
    } catch (e: Exception) {
      Log.e("CloseApp", "Failed to close database connections: ${e.message}")
    }
  }
}
