package com.mendix.mendixnative.react

import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

class NavigationModeModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    companion object {
        const val TAG = "NavigationModeModule"
        const val NAVIGATION_BAR_INTERACTION_MODE_THREE_BUTTON = 0
        const val NAVIGATION_BAR_INTERACTION_MODE_TWO_BUTTON = 1
        const val NAVIGATION_BAR_INTERACTION_MODE_GESTURE = 2
    }

    override fun getName(): String = "NavigationMode"

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun isNavigationBarActive(): Boolean {
        Log.d(TAG, "=== isNavigationBarActive called (sync) ===")
        return try {
            val context = reactApplicationContext
            Log.d(TAG, "Context: $context")

            val resources = context.resources
            Log.d(TAG, "Resources: $resources")

            val resourceId = resources.getIdentifier(
                "config_navBarInteractionMode",
                "integer",
                "android"
            )
            Log.d(TAG, "Resource ID: $resourceId")

            val mode = if (resourceId > 0) {
                val retrievedMode = resources.getInteger(resourceId)
                Log.d(TAG, "Retrieved mode from resources: $retrievedMode")
                retrievedMode
            } else {
                Log.w(TAG, "Resource not found, defaulting to THREE_BUTTON (0)")
                NAVIGATION_BAR_INTERACTION_MODE_THREE_BUTTON
            }

            Log.d(TAG, "Final mode value: $mode")

            // Navigation bar is active for three-button and two-button modes
            val isActive = mode == NAVIGATION_BAR_INTERACTION_MODE_THREE_BUTTON ||
                          mode == NAVIGATION_BAR_INTERACTION_MODE_TWO_BUTTON

            Log.d(TAG, "Is navigation bar active: $isActive")
            Log.d(TAG, "Returning: $isActive")

            isActive

        } catch (e: Exception) {
            Log.e(TAG, "Error in isNavigationBarActive", e)
            false
        }
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun getNavigationBarHeight(): Double {
        Log.d(TAG, "=== getNavigationBarHeight called (sync) ===")
        return try {
            val context = reactApplicationContext
            val resources = context.resources

            val resourceId = resources.getIdentifier("navigation_bar_height", "dimen", "android")
            val height = if (resourceId > 0) {
                val heightPx = resources.getDimensionPixelSize(resourceId)
                // Convert to dp for React Native
                val density = resources.displayMetrics.density
                val heightDp = heightPx / density
                Log.d(TAG, "Navigation bar height: ${heightPx}px = ${heightDp}dp")
                heightDp.toDouble()
            } else {
                Log.w(TAG, "Navigation bar height resource not found, returning 0")
                0.0
            }

            height

        } catch (e: Exception) {
            Log.e(TAG, "Error in getNavigationBarHeight", e)
            0.0
        }
    }
}
