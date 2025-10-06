import Foundation
import UIKit
import React
import Security
import React_RCTAppDelegate
import ReactAppDependencyProvider

public protocol ReactNativeDelegate: AnyObject {
    func onAppClosed()
}

@objcMembers
open class ReactNative: RCTAppDelegate, RCTReloadListener {
    // MARK: - Properties
    private var mendixApp: MendixApp?
    private var bundleUrl: URL?
    private var mendixOTAEnabled: Bool = false
    
    private var tapGestureHelper: TapGestureRecognizerHelper?
    
    public weak var delegate: ReactNativeDelegate?
    
    // Static properties
    private static var sharedInstance: ReactNative?
    
    // MARK: - Singleton
    
    public static var instance: ReactNative {
        guard let sharedInstance else {
            let instance = ReactNative()
            sharedInstance = instance
            return instance
        }
        return sharedInstance
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first { $0.isKeyWindow } ?? UIWindow(frame: UIScreen.main.bounds)
        
        moduleName = "App"
        automaticallyLoadReactNativeWindow = false
        dependencyProvider = RCTAppDependencyProvider()
        initialProps = [:]
        tapGestureHelper = TapGestureRecognizerHelper(window: window)
    }
    
    private var rootViewController: UIViewController? {
        window.rootViewController
    }
    
    public func changeRoot(to controller: UIViewController) {
        window.rootViewController = controller
        window.makeKeyAndVisible()
    }
    
    // MARK: - Public Static Methods
    static func warningsFilterToString(_ warningsFilter: WarningsFilter) -> String {
        return warningsFilter.stringValue
    }
    
    // MARK: - Setup Methods
    public func setup(_ mendixApp: MendixApp, launchOptions: [AnyHashable: Any]?) {
        self.mendixApp = mendixApp
        self.bundleUrl = mendixApp.bundleUrl
        self.initialProps = launchOptions
        
        if let host = bundleUrl?.host, let port = bundleUrl?.port {
            let jsLocation = "\(host):\(port)"
            RCTBundleURLProvider.sharedSettings().jsLocation = jsLocation
        }
    }
    
    func setup(_ mendixApp: MendixApp, launchOptions: [AnyHashable: Any]?, mendixOTAEnabled: Bool) {
        self.mendixOTAEnabled = mendixOTAEnabled
        setup(mendixApp, launchOptions: launchOptions)
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
        
        let rootView = rootViewFactory.view(withModuleName: "App")
        rootView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        rootView.frame = window.rootViewController?.view.frame ?? .zero
        window.rootViewController = mendixApp.reactLoading?.instantiateInitialViewController() ?? UIViewController()
        window.rootViewController?.view.addSubview(rootView)
        
        if let devSettings = turboModule(type: RCTDevSettings.self) {
            devSettings.isShakeToShowDevMenuEnabled = false
            devSettings.isDebuggingRemotely = isDebuggingRemotely()
        }
        
        showSplashScreen()
        
        if mendixApp.isDeveloperApp || mendixApp.enableThreeFingerGestures {
            attachThreeFingerGestures(to: window)
            DispatchQueue.main.async {
                RCTRegisterReloadCommandListener(self)
            }
        }
    }
    
    public func stop() {
        hideSplashScreen()
        initialProps = nil
        
        window.isHidden = false
        window.makeKeyAndVisible()
        
#if DEBUG
        if AppPreferences.elementInspectorEnabled {
            toggleElementInspector()
        }
        AppPreferences.elementInspectorEnabled = false
#endif
        rootViewFactory.bridge?.invalidate()
        
        removeThreeFingerGestures(from: window)
        window.rootViewController = rootViewController
        
        delegate?.onAppClosed()
        delegate = nil
        rootViewFactory.bridge = nil
    }
    
    // MARK: - State Methods
    public func isActive() -> Bool {
        return rootViewFactory.bridge != nil
    }
    
    // MARK: - Bundle Methods
    func getJSBundleFile() -> URL? {
        if hasNativeOtaBundle() {
            if let bundleUrl = OtaJSBundleFileProvider.getBundleUrl() {
                return bundleUrl
            }
        }
        
        return Bundle.main.url(forResource: "index.ios", withExtension: "bundle", subdirectory: "Bundle")
    }
    
    private func hasNativeOtaBundle() -> Bool {
        return FileManager.default.contents(atPath: OtaHelpers.getOtaManifestFilepath()) != nil
    }
    
    // MARK: - Splash Screen Methods
    func showSplashScreen() {
        if MendixBackwardsCompatUtility.isHideSplashScreenInClientSupported() {
            mendixApp?.splashScreenPresenter?.show(rootViewController?.view)
        }
    }
    
    func hideSplashScreen() {
        mendixApp?.splashScreenPresenter?.hide()
    }
    
    // MARK: - Reload Methods
    func reload() {
        showSplashScreen()
        
        if let mendixApp {
            let otaBundleUrl = OtaJSBundleFileProvider.getBundleUrl()
            if !mendixApp.isDeveloperApp, let otaBundleUrl = otaBundleUrl {
                RCTReloadCommandSetBundleURL(otaBundleUrl)
                //                rootViewFactory.bridge?.bundleURL = otaBundleUrl
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
    }
    
    private func reloadWithBridge() {
        RCTTriggerReloadCommandListeners("Reload command from app")
    }
    
    func reloadWithState() {
        UnsafeMxFunction.reloadClientWithState.perform()
    }
    
    // MARK: - RCTReloadListener
    @objc public func didReceiveReloadCommand() {
        showSplashScreen()
    }
    
    // MARK: - Debugging Methods
    func remoteDebugging(_ enable: Bool) {
        showSplashScreen()
        AppPreferences.remoteDebuggingEnabled = enable
        
        let appUrl = AppPreferences.safeAppUrl
        let port = AppPreferences.remoteDebuggingPackagerPort
        bundleUrl = AppUrl.forBundle(appUrl, port: port, isDebuggingRemotely: enable, isDevModeEnabled: true)
        turboModule(type: RCTDevSettings.self)?.isDebuggingRemotely = enable
    }
    
    func setRemoteDebuggingPackagerPort(_ port: Int) {
        AppPreferences.remoteDebuggingPackagerPort = port
        remoteDebugging(true)
    }
    
    func isDebuggingRemotely() -> Bool {
        return AppPreferences.devModeEnabled && AppPreferences.remoteDebuggingEnabled
    }
    
    // MARK: - Menu and Inspector Methods
    public func showAppMenu() {
        turboModule(type: RCTDevMenu.self)?.show()
    }
    
    func toggleElementInspector() {
        turboModule(type: RCTDevSettings.self)?.toggleElementInspector()
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
        if gestureRecognizer.state == .ended && isActive() {
            reloadWithState()
        }
    }
    
    // MARK: - Legacy Methods (for compatibility)
    func useCodePush() -> Bool {
        // Implementation depends on your specific CodePush setup
        return false
    }
    
    func turboModule<T: NSObject>(type: T.Type) -> T? {
        return rootViewFactory.bridge?.moduleRegistry.module(for: type.self) as? T
    }
    
    public override func sourceURL(for bridge: RCTBridge) -> URL? {
        return self.bundleURL()
    }
    
    public override func bundleURL() -> URL? {
        return bundleUrl
    }
}
