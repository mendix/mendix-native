package com.mendix.mendixnative.react

import com.facebook.react.bridge.ReactContext
import org.pgsqlite.SQLitePlugin

fun closeSqlDatabaseConnection(reactContext: ReactContext?) = reactContext?.let {
    (it.catalystInstance.getNativeModule("SQLite") as SQLitePlugin).closeAllOpenDatabases()
}
