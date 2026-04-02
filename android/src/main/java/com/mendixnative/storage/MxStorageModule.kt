package com.mendixnative.storage

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.annotations.ReactModule
import com.mendixnative.NativeMxStorageSpec
import com.op.sqlite.OPSQLiteModule

@ReactModule(name = MxStorageModule.NAME)
class MxStorageModule(reactContext: ReactApplicationContext) :
    NativeMxStorageSpec(reactContext) {

  override fun getName(): String = NAME

  override fun clearDatabases(promise: Promise) {
    val opSQLiteModule = reactApplicationContext.getNativeModule(OPSQLiteModule::class.java)
    if (opSQLiteModule != null) {
      try {
        opSQLiteModule.deleteAllDBs()
        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("STORAGE_CLEAR_FAILED", "Failed to clear databases: ${e.message}", e)
      }
    } else {
      promise.reject("MODULE_NOT_FOUND", "OPSQLiteModule not available")
    }
  }

  override fun closeDatabaseConnections(promise: Promise) {
    val opSQLiteModule = reactApplicationContext.getNativeModule(OPSQLiteModule::class.java)
    if (opSQLiteModule != null) {
      try {
        opSQLiteModule.closeAllConnections()
        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("STORAGE_CLOSE_FAILED", "Failed to close database connections: ${e.message}", e)
      }
    } else {
      promise.reject("MODULE_NOT_FOUND", "OPSQLiteModule not available")
    }
  }

  companion object {
    const val NAME = "MxStorage"
  }
}
