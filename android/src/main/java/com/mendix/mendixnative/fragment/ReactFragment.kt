package com.mendix.mendixnative.fragment

import android.content.Intent
import android.os.Bundle
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import com.facebook.react.ReactApplication
import com.facebook.react.ReactDelegate
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeHost
import com.facebook.react.modules.core.PermissionAwareActivity
import com.facebook.react.modules.core.PermissionListener
import com.mendix.mendixnative.react.CopiedFrom


/**
 * Fragment for creating a React View. This allows the developer to "embed" a React Application
 * inside native components such as a Drawer, ViewPager, etc.
 */
@CopiedFrom(com.facebook.react.ReactFragment::class)
open class ReactFragment : Fragment(), PermissionAwareActivity {
  private var mReactDelegate: ReactDelegate? = null
  private var mPermissionListener: PermissionListener? = null

  // region Lifecycle
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    var mainComponentName: String? = null
    var launchOptions: Bundle? = null
    if (arguments != null) {
      mainComponentName = requireArguments().getString(ARG_COMPONENT_NAME)
      launchOptions = requireArguments().getBundle(ARG_LAUNCH_OPTIONS)
    }
    checkNotNull(mainComponentName) { "Cannot loadApp if component name is null" }
    mReactDelegate = ReactDelegate(activity, reactHost, mainComponentName, launchOptions)
  }

  /**
   * Get the [ReactNativeHost] used by this app. By default, assumes [ ][Activity.getApplication] is an instance of [ReactApplication] and calls [ ][ReactApplication.getReactNativeHost]. Override this method if your application class does not
   * implement `ReactApplication` or you simply have a different mechanism for storing a
   * `ReactNativeHost`, e.g. as a static field somewhere.
   */
  protected val reactNativeHost: ReactNativeHost
    get() = (requireActivity().application as ReactApplication).reactNativeHost

  protected val reactHost: ReactHost?
    get() = (requireActivity().application as ReactApplication).reactHost

  override fun onCreateView(
    inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
  ): View? {
    mReactDelegate!!.loadApp()
    // Adds tapjacking protection to the rootview
    mReactDelegate!!.reactRootView?.filterTouchesWhenObscured = true
    return mReactDelegate!!.reactRootView
  }

  override fun onResume() {
    super.onResume()
    mReactDelegate!!.onHostResume()
  }

  override fun onPause() {
    super.onPause()
    mReactDelegate!!.onHostPause()
  }

  override fun onDestroy() {
    super.onDestroy()
    mReactDelegate!!.onHostDestroy()
  }

  // endregion
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
    mReactDelegate!!.onActivityResult(requestCode, resultCode, data, true)
  }

  /**
   * Helper to forward hardware back presses to our React Native Host
   *
   *
   * This must be called via a forward from your host Activity
   */
  fun onBackPressed(): Boolean {
    return mReactDelegate!!.onBackPressed()
  }

  /**
   * Helper to forward onKeyUp commands from our host Activity. This allows ReactFragment to handle
   * double tap reloads and dev menus
   *
   *
   * This must be called via a forward from your host Activity
   *
   * @param keyCode keyCode
   * @param event event
   * @return true if we handled onKeyUp
   */
  open fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
    return mReactDelegate!!.shouldShowDevMenuOrReload(keyCode, event)
  }

  override fun onRequestPermissionsResult(
    requestCode: Int, permissions: Array<String>, grantResults: IntArray
  ) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    if (mPermissionListener != null
      && mPermissionListener!!.onRequestPermissionsResult(requestCode, permissions, grantResults)
    ) {
      mPermissionListener = null
    }
  }

  override fun checkPermission(permission: String, pid: Int, uid: Int): Int {
    return requireActivity().checkPermission(permission, pid, uid)
  }

  override fun checkSelfPermission(permission: String): Int {
    return requireActivity().checkSelfPermission(permission)
  }

  override fun requestPermissions(
    permissions: Array<String>,
    requestCode: Int,
    listener: PermissionListener?
  ) {
    mPermissionListener = listener
    requestPermissions(permissions, requestCode)
  }

  /** Builder class to help instantiate a ReactFragment  */
  class Builder {
    var mComponentName: String? = null
    var mLaunchOptions: Bundle? = null

    /**
     * Set the Component name for our React Native instance.
     *
     * @param componentName The name of the component
     * @return Builder
     */
    fun setComponentName(componentName: String?): Builder {
      mComponentName = componentName
      return this
    }

    /**
     * Set the Launch Options for our React Native instance.
     *
     * @param launchOptions launchOptions
     * @return Builder
     */
    fun setLaunchOptions(launchOptions: Bundle?): Builder {
      mLaunchOptions = launchOptions
      return this
    }

    fun build(): ReactFragment {
      return newInstance(mComponentName, mLaunchOptions)
    }
  }

  companion object {
    private const val ARG_COMPONENT_NAME = "arg_component_name"
    private const val ARG_LAUNCH_OPTIONS = "arg_launch_options"

    /**
     * @param componentName The name of the react native component
     * @return A new instance of fragment ReactFragment.
     */
    private fun newInstance(componentName: String?, launchOptions: Bundle?): ReactFragment {
      val fragment = ReactFragment()
      val args = Bundle()
      args.putString(ARG_COMPONENT_NAME, componentName)
      args.putBundle(ARG_LAUNCH_OPTIONS, launchOptions)
      fragment.arguments = args
      return fragment
    }
  }
}
