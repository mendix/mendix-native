package com.mendix.mendixnative.devsupport

import android.content.Context
import com.facebook.react.common.SurfaceDelegateFactory
import com.facebook.react.devsupport.DevSupportManagerFactory
import com.facebook.react.devsupport.ReactInstanceDevHelper
import com.facebook.react.devsupport.ReleaseDevSupportManager
import com.facebook.react.devsupport.interfaces.DevBundleDownloadListener
import com.facebook.react.devsupport.interfaces.DevLoadingViewManager
import com.facebook.react.devsupport.interfaces.DevSupportManager
import com.facebook.react.devsupport.interfaces.PausedInDebuggerOverlayManager
import com.facebook.react.devsupport.interfaces.RedBoxHandler
import com.facebook.react.packagerconnection.RequestHandler

/**
 * A [DevSupportManagerFactory] that creates [MendixBridgelessDevSupportManager] instances
 * with a custom [DevBundleDownloadListener] injected at construction time.
 *
 * This replaces the need for reflection-based listener injection.
 */
class MendixDevSupportManagerFactory(
    private val devBundleDownloadListener: DevBundleDownloadListener?,
) : DevSupportManagerFactory {

    @Deprecated("Use the create() overload with useDevSupport parameter for New Architecture.")
    override fun create(
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
    ): DevSupportManager {
        return if (!enableOnCreate) {
            ReleaseDevSupportManager()
        } else {
            MendixBridgelessDevSupportManager(
                applicationContext,
                reactInstanceManagerHelper,
                packagerPathForJSBundleName,
                enableOnCreate,
                redBoxHandler,
                this.devBundleDownloadListener,
                minNumShakes,
                customPackagerCommandHandlers,
                surfaceDelegateFactory,
                devLoadingViewManager,
                pausedInDebuggerOverlayManager,
            )
        }
    }

    override fun create(
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
        useDevSupport: Boolean,
    ): DevSupportManager {
        return if (useDevSupport) {
            MendixBridgelessDevSupportManager(
                applicationContext,
                reactInstanceManagerHelper,
                packagerPathForJSBundleName,
                enableOnCreate,
                redBoxHandler,
                this.devBundleDownloadListener, // Our injected listener, ignoring the null passed by ReactHostImpl
                minNumShakes,
                customPackagerCommandHandlers,
                surfaceDelegateFactory,
                devLoadingViewManager,
                pausedInDebuggerOverlayManager,
            )
        } else {
            ReleaseDevSupportManager()
        }
    }
}
