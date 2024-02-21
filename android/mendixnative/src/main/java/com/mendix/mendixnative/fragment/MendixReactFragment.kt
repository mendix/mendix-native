package com.mendix.mendixnative.fragment

import android.content.Intent
import android.os.Bundle
import android.view.KeyEvent
import android.view.MotionEvent
import com.mendix.mendixnative.DevAppMenuHandler
import com.mendix.mendixnative.MendixApplication
import com.mendix.mendixnative.MendixInitializer
import com.mendix.mendixnative.activity.LaunchScreenHandler
import com.mendix.mendixnative.react.MendixApp
import com.mendix.mendixnative.react.NativeReloadHandler
import com.mendix.mendixnative.react.menu.DevAppMenu
import com.mendix.mendixnative.util.MendixDoubleTapRecognizer

/**
 * Class used for Sample apps
 */
open class MendixReactFragment : ReactFragment(), MendixReactFragmentView {

    protected var mendixApp: MendixApp? = null
    private lateinit var mendixInitializer: MendixInitializer
    private var doubleTapReloadRecognizer = MendixDoubleTapRecognizer()

    companion object {
        const val ARG_MENDIX_APP = "arg_mendix_app"
        const val ARG_CLEAR_DATA = "arg_clear_data"
        const val ARG_USE_DEVELOPER_SUPPORT = "arg_use_developer_support"
        const val ARG_COMPONENT_NAME = "arg_component_name"
        const val ARG_LAUNCH_OPTIONS = "arg_launch_options"

        fun newInstance(
            componentName: String,
            launchOptions: Bundle?,
            mendixApp: MendixApp,
            clearData: Boolean,
            useDeveloperSupport: Boolean
        ): MendixReactFragment {
            val mendixReactFragment = MendixReactFragment()
            val args = Bundle()
            args.putString(ARG_COMPONENT_NAME, componentName)
            args.putBundle(ARG_LAUNCH_OPTIONS, launchOptions)
            args.putBoolean(ARG_CLEAR_DATA, clearData)
            args.putBoolean(ARG_USE_DEVELOPER_SUPPORT, useDeveloperSupport)
            args.putSerializable(ARG_MENDIX_APP, mendixApp)
            mendixReactFragment.arguments = args
            return mendixReactFragment
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        (activity !is LaunchScreenHandler).let {
            if (it) throw java.lang.IllegalArgumentException("The Activity needs to implement LaunchScreenHandler")
        }

        if (mendixApp == null) {
            mendixApp = requireArguments().getSerializable(ARG_MENDIX_APP) as MendixApp?
                ?: throw IllegalArgumentException("Mendix app is required")
        }

        val clearData = requireArguments().getBoolean(ARG_CLEAR_DATA, false)
        val hasRNDeveloperSupport = requireArguments().getBoolean(ARG_USE_DEVELOPER_SUPPORT, false)

        mendixInitializer =
            MendixInitializer(requireActivity(), reactNativeHost, hasRNDeveloperSupport).also {
                it.onCreate(mendixApp!!, this, clearData)
            }

        super.onCreate(savedInstanceState)
    }

    fun onNewIntent(intent: Intent) {
        if (reactNativeHost.hasInstance()) {
            reactNativeHost.reactInstanceManager.onNewIntent(intent);
        }
    }

    override fun onDestroy() {
        mendixInitializer.onDestroy()
        super.onDestroy()
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_MENU || doubleTapReloadRecognizer.didDoubleTapBacktick(
                keyCode,
                view
            )
        ) {
            showDevAppMenu()
            return true
        }
        return super.onKeyUp(keyCode, event)
    }

    override fun showDevAppMenu() {
        activity?.let {
            DevAppMenu(it, mendixApp!!.showExtendedDevMenu, {
                (it.application as MendixApplication).reactNativeHost.reactInstanceManager.currentReactContext?.getNativeModule(
                    NativeReloadHandler::class.java
                )?.reload()
            }, { if (!this.isDetached) this.onCloseProjectSelected() }).show()
        }
    }

    open fun onCloseProjectSelected() {
        // Closing shake detection to avoid dialog from triggering while closing
        mendixInitializer.stopShakeDetector();
    }

    override fun dispatchTouchEvent(ev: MotionEvent?): Boolean {
        return mendixInitializer.dispatchTouchEvent(ev)
    }
}

interface MendixReactFragmentView : DevAppMenuHandler, TouchEventDispatcher, BackButtonHandler {
    fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean
}

interface TouchEventDispatcher {
    fun dispatchTouchEvent(ev: MotionEvent?): Boolean
}

interface BackButtonHandler {
    fun onBackPressed(): Boolean
}
