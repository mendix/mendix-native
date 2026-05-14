package com.mendix.mendixnative.devsupport

import android.content.Context
import com.facebook.react.bridge.UiThreadUtil
import com.facebook.react.common.SurfaceDelegateFactory
import com.facebook.react.devsupport.DevSupportManagerBase
import com.facebook.react.devsupport.ReactInstanceDevHelper
import com.facebook.react.devsupport.interfaces.DevBundleDownloadListener
import com.facebook.react.devsupport.interfaces.DevLoadingViewManager
import com.facebook.react.devsupport.interfaces.PausedInDebuggerOverlayManager
import com.facebook.react.devsupport.interfaces.RedBoxHandler
import com.facebook.react.packagerconnection.RequestHandler

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
    override val uniqueTag: String get() = "MendixBridgeless"

    override fun handleReloadJS() {
        UiThreadUtil.assertOnUiThread()
        hideRedboxDialog()
        reactInstanceDevHelper.reload("MendixBridgelessDevSupportManager.handleReloadJS()")
    }
}
