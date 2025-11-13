package com.mendix.mendixnative.react.menu

import android.app.Activity
import android.app.AlertDialog
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.Toast
import com.mendix.mendixnative.MendixApplication
import com.mendixnative.R
import com.mendixnative.databinding.AppMenuLayoutBinding
import com.mendix.mendixnative.config.AppPreferences
import com.mendix.mendixnative.react.clearDataWithReactContext
import com.mendix.mendixnative.react.reactContext
import com.mendix.mendixnative.react.toggleElementInspector

class DevAppMenu(
  val activity: Activity,
  isDevModeEnabled: Boolean = false,
  handleReload: () -> Unit,
  onCloseProjectSelected: (() -> Unit)? = null
) : AppMenu {
  private val dialog: AlertDialog

  init {
    val preferences = AppPreferences(activity.applicationContext)
    val binding = AppMenuLayoutBinding.inflate(LayoutInflater.from(activity))
    val view = binding.root

    binding.advancedSettingsButton

    dialog = AlertDialog.Builder(activity)
      .setView(view)
      .create()

    binding.advancedSettingsContainer.visibility = View.GONE
    binding.advancedSettingsButton.visibility = visibleWhenDevModeEnabled(isDevModeEnabled)
    binding.advancedSettingsButton.setOnClickListener {
      binding.advancedSettingsContainer.visibility =
        when (binding.advancedSettingsContainer.visibility) {
          (View.GONE) -> View.VISIBLE
          else -> View.GONE
        }
    }

    binding.remoteDebuggingButton.visibility = visibleWhenDevModeEnabled(isDevModeEnabled)
    binding.remoteDebuggingButton.text =
      activity.resources.getText(remoteDebugginButtonTextResource(preferences.isRemoteJSDebugEnabled))
    binding.remoteDebuggingButton.setOnClickListener {
      preferences.setRemoteDebugging(!preferences.isRemoteJSDebugEnabled)
      handleReload()
      binding.remoteDebuggingButton.text =
        activity.resources.getText(remoteDebugginButtonTextResource(preferences.isRemoteJSDebugEnabled))
      dialog.dismiss()
    }

    binding.advancedClearData.setOnClickListener {
      activity.runOnUiThread {
        clearDataWithReactContext(
          activity.application,
          (activity.application as MendixApplication).reactNativeHost
        ) { success: Boolean ->
          if (success) {
            activity.runOnUiThread {
              handleReload()
            }
          } else {
            Toast.makeText(activity, "Clearing data failed.", Toast.LENGTH_LONG).show()
          }
        }
      }
      dialog.dismiss()
    }

    binding.elementInspectorButton.visibility = visibleWhenDevModeEnabled(isDevModeEnabled)
    binding.elementInspectorButton.setOnClickListener {
      preferences.setElementInspector(!preferences.isElementInspectorEnabled)
      toggleElementInspector((activity.application as MendixApplication).reactNativeHost.reactContext())
      dialog.dismiss()
    }

    binding.reloadButton.setOnClickListener {
      handleReload()
      dialog.dismiss()
    }

    binding.closeButton.setOnClickListener {
      dialog.dismiss()
      onCloseProjectSelected?.invoke()
    }
  }

  override fun show() {
    if (!activity.isDestroyed) {
      dialog.show()
    } else {
      Log.d("DevAppMenu", "Attempted to show dialog in a destroyed activity")
    }
  }

  private fun visibleWhenDevModeEnabled(devModeEnabled: Boolean): Int = if (devModeEnabled) {
    View.VISIBLE
  } else {
    View.GONE
  }

  private fun remoteDebugginButtonTextResource(isRemoteJsDebugEnabled: Boolean): Int =
    if (isRemoteJsDebugEnabled) {
      R.string.dev_menu_disable_remote_debugging
    } else {
      R.string.dev_menu_enable_remote_debugging
    }
}
