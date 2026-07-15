package com.mendix.mendixnative.fragment

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup

/**
 * Mendix's [com.facebook.react.ReactFragment] extension.
 *
 * Adds two behaviors on top of upstream that aren't available in RN itself:
 * - tapjacking protection on the react root view
 * - always forwarding [onActivityResult] to the React instance, since Mendix embeds React
 *   fragments inside native navigation (Drawer/ViewPager/Nav) where the host activity's result
 *   is meant for the React app.
 */
open class ReactFragment : com.facebook.react.ReactFragment() {

  override fun onCreateView(
    inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
  ): View? {
    val view = super.onCreateView(inflater, container, savedInstanceState)
    reactDelegate.reactRootView?.filterTouchesWhenObscured = true
    return view
  }

  @Suppress("DEPRECATION")
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
    reactDelegate.onActivityResult(requestCode, resultCode, data, true)
  }
}
