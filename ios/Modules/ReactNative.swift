import UIKit
import React

public protocol ReactNativeDelegateInternal: AnyObject {
    func onAppClosed()
}

@objcMembers
open class ReactNative: NSObject, RCTReloadListener {
    // MARK: - Properties
    private var mendixApp: MendixApp?
    private var bundleUrl: URL?
    private var mendixOTAEnabled: Bool = false
    private var tapGestureHelper: TapGestureRecognizerHelper?
    
    public weak var delegate: ReactNativeDelegateInternal?
    
    // MARK: - Singleton
    public static let shared = ReactNative()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Setup Methods
    public func setup(_ mendixApp: MendixApp, launchOptions: [AnyHashable: Any]? = nil, mendixOTAEnabled: Bool = false) {
        self.mendixApp = mendixApp
        self.bundleUrl = mendixApp.bundleUrl
        self.mendixOTAEnabled = mendixOTAEnabled
        
        if let host = bundleUrl?.host, let port = bundleUrl?.port {
            let jsLocation = "\(host):\(port)"
            RCTBundleURLProvider.sharedSettings().jsLocation = jsLocation
        }
    }
    
    // MARK: - Lifecycle Methods
    public func start() {
        guard let mendixApp = self.mendixApp else {
            fatalError("MendixApp not passed before starting the app")
        }
        
        MxConfiguration.update(from: mendixApp)
        
        if mendixApp.clearDataAtLaunch {
            StorageHelper.clearAll()
        }
        
        ReactAppProvider.shared()?.setReactViewController(mendixApp.reactLoading?.instantiateInitialViewController() ?? UIViewController())
        
        DevHelper.setShakeToShowDevMenuEnabled(enabled: AppPreferences.devModeEnabled)
        DevHelper.setDebugMode(enabled: AppPreferences.devModeEnabled && AppPreferences.remoteDebuggingEnabled)
        
        showSplashScreen()
        
        if mendixApp.isDeveloperApp || mendixApp.enableThreeFingerGestures {
            DispatchQueue.main.async {
                RCTRegisterReloadCommandListener(self)
            }
        }
    }
    
    public func stop() {
        hideSplashScreen()
        delegate?.onAppClosed()
        delegate = nil
    }
    
    // MARK: - Splash Screen Methods
    public func showSplashScreen() {
        if MendixBackwardsCompatUtility.isHideSplashScreenInClientSupported() {
            mendixApp?.splashScreenPresenter?.show(ReactAppProvider.shared()?.rootView)
        }
    }
    
    public func hideSplashScreen() {
        mendixApp?.splashScreenPresenter?.hide()
        DevHelper.hideDevLoadingView()
    }
    
    // MARK: - Reload Methods
    public func reload() {
        guard let mendixApp = mendixApp else { return }

        // Note: under the New Architecture the bundle URL is resolved fresh in bundleURL(),
        // which RCTHost re-invokes on reload. RCTReloadCommandSetBundleURL is a legacy-bridge
        // mechanism that the bridgeless host ignores, so it is intentionally not used here.

        if mendixApp.isDeveloperApp {
            let runtimeInfoUrl = AppUrl.forRuntimeInfo(mendixApp.runtimeUrl.absoluteString)
            RuntimeInfoProvider.getRuntimeInfo(runtimeInfoUrl) { [weak self] response in
                if response.status == "SUCCESS", let version = response.runtimeInfo?.version {
                    MendixBackwardsCompatUtility.update(version)
                }
                self?.reloadWithBridge()
            }
        } else {
            reloadWithBridge()
        }
    }
    
    private func reloadWithBridge() {
        RCTTriggerReloadCommandListeners("Reload command from app")
    }
    
    public func reloadWithState() {
        ReactHostHelper().reloadClientWithState()
    }
    
    // MARK: - RCTReloadListener
    @objc public func didReceiveReloadCommand() {
        showSplashScreen()
    }
    
    // MARK: - Debugging Methods
    public func remoteDebugging(_ enable: Bool) {
        showSplashScreen()
        bundleUrl = AppUrl.forBundle(
            AppPreferences.safeAppUrl,
            port: AppPreferences.remoteDebuggingPackagerPort,
            isDebuggingRemotely: enable,
            isDevModeEnabled: true
        )
        DevHelper.setDebugMode(enabled: enable)
    }
    
    public func setRemoteDebuggingPackagerPort(_ port: Int) {
        AppPreferences.remoteDebuggingPackagerPort = port
        remoteDebugging(true)
    }
    
    // MARK: - Gesture Recognition
    private func attachThreeFingerGestures(to window: UIWindow) {
        tapGestureHelper?.attach()
    }
    
    private func removeThreeFingerGestures(from window: UIWindow) {
        tapGestureHelper?.remove()
        window.motionBegan(.motionShake, with: nil)
    }
    
    @objc private func appReloadAction(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended && ReactAppProvider.isReactAppActive() == true {
            reloadWithState()
        }
    }
    
    // MARK: - Legacy Methods (for compatibility)
    func useCodePush() -> Bool {
        // Implementation depends on your specific CodePush setup
        return false
    }
    
    public func bundleURL() -> URL? {
        // New Architecture (Bridgeless): RCTHost re-invokes this provider block on every
        // reload (via RCTRootViewFactory's bundleURLBlock) instead of consulting the URL set
        // by RCTReloadCommandSetBundleURL. Resolve the OTA bundle fresh here so a freshly
        // deployed OTA bundle is picked up after reload. Without this, every reload re-loads
        // the bundle captured at host-creation time and the app loops:
        // download -> deploy -> reload -> same bundle.
        //
        // For the developer app (and remote debugging) the cached packager URL must be used,
        // so only the production path re-resolves through BundleHelper.
        if mendixApp?.isDeveloperApp == true {
            return bundleUrl
        }
        return BundleHelper.getJSBundleFile()
    }
}

