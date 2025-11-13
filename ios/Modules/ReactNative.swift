import UIKit
import React

public protocol ReactNativeDelegate: AnyObject {
    func onAppClosed()
}

@objcMembers
open class ReactNative: NSObject, RCTReloadListener {
    // MARK: - Properties
    private var mendixApp: MendixApp?
    private var bundleUrl: URL?
    private var mendixOTAEnabled: Bool = false
    private var tapGestureHelper: TapGestureRecognizerHelper?
    
    public weak var delegate: ReactNativeDelegate?
    
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
        
        DevHelper.devSettings?.isShakeToShowDevMenuEnabled = false
        DevHelper.devSettings?.isDebuggingRemotely = AppPreferences.devModeEnabled && AppPreferences.remoteDebuggingEnabled
        
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
        
        let otaBundleUrl = OtaJSBundleFileProvider.getBundleUrl()
        if !mendixApp.isDeveloperApp, let otaBundleUrl = otaBundleUrl {
            RCTReloadCommandSetBundleURL(otaBundleUrl)
        }
        
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
        UnsafeMxFunction.reloadClientWithState.perform()
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
        return bundleUrl
    }
}

