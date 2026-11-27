package com.mendix.mendixnative.devsupport

import android.content.Context
import com.facebook.react.bridge.UiThreadUtil
import com.facebook.react.common.SurfaceDelegateFactory
import com.facebook.react.devsupport.DevSupportManagerBase
import com.facebook.react.devsupport.ReactInstanceDevHelper
import com.facebook.react.devsupport.interfaces.DevBundleDownloadListener
import com.facebook.react.devsupport.interfaces.DevLoadingViewManager
import com.facebook.react.devsupport.interfaces.PackagerStatusCallback
import com.facebook.react.devsupport.interfaces.PausedInDebuggerOverlayManager
import com.facebook.react.devsupport.interfaces.RedBoxHandler
import com.facebook.react.packagerconnection.RequestHandler
import com.mendix.mendixnative.config.AppPreferences

/**
 * A public DevSupportManager implementation for Mendix apps in bridgeless mode.
 *
 * This mirrors the behavior of React Native's internal [BridgelessDevSupportManager]
 * but is accessible from external modules, allowing us to inject a custom
 * [DevBundleDownloadListener] at construction time without reflection.
 */
class MendixBridgelessDevSupportManager(
    applicationContext: Context,
    reactInstanceManagerHelper: ReactInstanceDevHelper,
    packagerPathForJSBundleName: String?,
    enableOnCreate: Boolean,
    redBoxHandler: RedBoxHandler?,
    devBundleDownloadListener: DevBundleDownloadListener?,
    minNumShakes: Int,
    customPackagerCommandHandlers: Map<String, RequestHandler>?,
    surfaceDelegateFactory: SurfaceDelegateFactory?,
    devLoadingViewManager: DevLoadingViewManager?,
    pausedInDebuggerOverlayManager: PausedInDebuggerOverlayManager?,
) : DevSupportManagerBase(
    applicationContext,
    reactInstanceManagerHelper,
    packagerPathForJSBundleName,
    enableOnCreate,
    redBoxHandler,
    devBundleDownloadListener,
    minNumShakes,
    customPackagerCommandHandlers,
    surfaceDelegateFactory,
    devLoadingViewManager,
    pausedInDebuggerOverlayManager,
) {
    private val mxContext: Context = applicationContext

    override val uniqueTag: String get() = "MendixBridgeless"

    /**
     * React Native's [com.facebook.react.packagerconnection.PackagerConnectionSettings] caches the
     * resolved debug server host in a static field. When nothing is stored yet, a background read
     * (e.g. opening the packager websocket when this manager is created) resolves the emulator
     * default (10.0.2.2:8081) and writes it to that cache after we have already set the host for
     * the Mendix app, overwriting it. Metro would then be reported as not running and
     * [com.facebook.react.runtime.ReactHostImpl] falls back to the asset bundle, which doesn't exist
     * in developer builds ("Unable to load script").
     *
     * Re-apply the host Mendix stored for this app right before the check so it always wins.
     */
    override fun isPackagerRunning(callback: PackagerStatusCallback) {
        val storedHost = AppPreferences(mxContext).metroBundlerHost
        if (storedHost.isNotEmpty()) {
            devSettings.packagerConnectionSettings.debugServerHost = storedHost
        }
        super.isPackagerRunning(callback)
    }

    override fun handleReloadJS() {
        UiThreadUtil.assertOnUiThread()
        hideRedboxDialog()
        reactInstanceDevHelper.reload("MendixBridgelessDevSupportManager.handleReloadJS()")
    }
}
