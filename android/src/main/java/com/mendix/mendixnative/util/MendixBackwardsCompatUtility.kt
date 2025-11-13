package com.mendix.mendixnative.util

data class UnsupportedFeatures(val reloadInClient: Boolean = false, val hideSplashScreenInClient: Boolean = false);

class MendixBackwardsCompatUtility private constructor() {
    companion object {
        @Volatile
        private var INSTANCE: MendixBackwardsCompatUtility? = null

        fun getInstance(): MendixBackwardsCompatUtility {
            return synchronized(this) {
                if (INSTANCE != null) {
                    INSTANCE!!
                } else {
                    INSTANCE = MendixBackwardsCompatUtility()
                    INSTANCE!!
                }

            }
        }

        fun update(forVersion: String) {
            getInstance().update(forVersion)
        }
    }

    private val versionMap = emptyMap<String, UnsupportedFeatures>()
    var unsupportedFeatures: UnsupportedFeatures = UnsupportedFeatures()
        private set

    private fun update(forVersion: String) {
        val versionParts = forVersion.split(".")
        unsupportedFeatures = versionMap[versionParts.take(versionParts.size.coerceAtMost(3)).joinToString(".")]
                ?: versionMap[versionParts.take(versionParts.size.coerceAtMost(2)).joinToString(".")]
                        ?: versionMap[versionParts[0]] ?: UnsupportedFeatures()
    }
}
