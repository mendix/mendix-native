import Foundation
import UIKit
import React
import Security
import RNCAsyncStorage
import React_RCTAppDelegate

public protocol ReactNativeDelegate: AnyObject {
    func onAppClosed()
}

public class ReactNative: NSObject, RCTReloadListener {
    // MARK: - Properties
    private var rootWindow: UIWindow?
    private var mendixApp: MendixApp?
    private var bundleUrl: URL?
    private var launchOptions: [AnyHashable: Any]?
    private var mendixOTAEnabled: Bool = false
    private var tapGestureRecognizer: UITapGestureRecognizer?
    private var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
    public weak var delegate: ReactNativeDelegate?
    
    var bridge: RCTBridge? {
        return RCTBridge.current()
    }
    
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
        rootWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first { $0.isKeyWindow }
    }
    
    private var rootViewController: UIViewController? {
        rootWindow?.rootViewController
    }
    
    // MARK: - Public Static Methods
    static func warningsFilterToString(_ warningsFilter: WarningsFilter) -> String {
        return warningsFilter.stringValue
    }
    
    static func toAppScopeKey(_ key: String) -> String {
        guard let appName = MxConfiguration.appName, !appName.isEmpty else {
            return key
        }
        return "\(appName)_\(key)"
    }
    
    public static func clearKeychain() {
        let keys = [
            ReactNative.toAppScopeKey("token"),
            ReactNative.toAppScopeKey("session")
        ]
        
        for key in keys {
            deleteKeychainItem(withKey: key)
        }
    }
    
    private static func deleteKeychainItem(withKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Setup Methods
    public func setup(_ mendixApp: MendixApp, launchOptions: [AnyHashable: Any]?) {
        self.mendixApp = mendixApp
        self.bundleUrl = mendixApp.bundleUrl
        self.launchOptions = launchOptions
        
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
        
        guard let rootViewFactory = (RCTSharedApplication()?.delegate as? RCTAppDelegate)?.rootViewFactory else {
            fatalError("RCTRootViewFactory should not be nil")
        }
        
        MxConfiguration.runtimeUrl = mendixApp.runtimeUrl
        MxConfiguration.appName = mendixApp.identifier
        MxConfiguration.isDeveloperApp = mendixApp.isDeveloperApp
        
        if let identifier = mendixApp.identifier {
            MxConfiguration.databaseName = identifier
            MxConfiguration.filesDirectoryName = "files/\(identifier)"
        }
        
        MxConfiguration.warningsFilter = mendixApp.warningsFilter
        
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000.0)
        let randomValue = arc4random_uniform(1000)
        MxConfiguration.appSessionId = "\(randomValue)\(timestamp)"
        
        if mendixApp.clearDataAtLaunch {
            clearData()
        }
        
        let appLoadingController: UIViewController
        if let reactLoading = mendixApp.reactLoading {
            appLoadingController = reactLoading.instantiateInitialViewController()!
        } else {
            appLoadingController = UIViewController()
        }
        
        
        
        let reactRootView = rootViewFactory.view(withModuleName: "App")
        reactRootView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if let rootWindow = self.rootWindow {
            reactRootView.frame = rootWindow.rootViewController?.view.frame ?? .zero
            rootWindow.rootViewController = appLoadingController
            rootWindow.rootViewController?.view.addSubview(reactRootView)
        }
        
        if let devSettings = turboModule(type: RCTDevSettings.self) {
            devSettings.isShakeToShowDevMenuEnabled = false
            devSettings.isDebuggingRemotely = isDebuggingRemotely()
        }
        
        showSplashScreen()
        
        if mendixApp.isDeveloperApp || mendixApp.enableThreeFingerGestures {
            if let rootWindow = self.rootWindow {
                attachThreeFingerGestures(to: rootWindow)
            }
            
            DispatchQueue.main.async {
                RCTRegisterReloadCommandListener(self)
            }
        }
    }
    
    public func stop() {
        hideSplashScreen()
        launchOptions = nil
        
        rootWindow?.isHidden = false
        rootWindow?.makeKeyAndVisible()
        
#if DEBUG
        if AppPreferences.elementInspectorEnabled {
            toggleElementInspector()
        }
        AppPreferences.elementInspectorEnabled = false
#endif
        bridge?.invalidate()
        
        if let rootWindow = self.rootWindow {
            removeThreeFingerGestures(from: rootWindow)
            rootWindow.rootViewController = rootViewController
        }
        
        delegate?.onAppClosed()
        delegate = nil
//        bridge = nil
    }
    
    // MARK: - State Methods
    public func isActive() -> Bool {
        return bridge != nil
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
        guard let unsupportedFeatures = MendixBackwardsCompatUtility.unsupportedFeatures(),
              !unsupportedFeatures.hideSplashScreenInClient,
              let splashScreenPresenter = mendixApp?.splashScreenPresenter else {
            return
        }
        
        splashScreenPresenter.show(getRootView())
    }
    
    func hideSplashScreen() {
        mendixApp?.splashScreenPresenter?.hide()
    }
    
    // MARK: - Reload Methods
    func reload() {
        showSplashScreen()
        
        if let mendixApp = self.mendixApp {
            let otaBundleUrl = OtaJSBundleFileProvider.getBundleUrl()
            if !mendixApp.isDeveloperApp, let otaBundleUrl = otaBundleUrl {
                bridge?.bundleURL = otaBundleUrl
            }
            
            if mendixApp.isDeveloperApp {
                let runtimeInfoUrl = AppUrl.forRuntimeInfo(mendixApp.runtimeUrl.absoluteString)
                RuntimeInfoProvider.getRuntimeInfo(runtimeInfoUrl) { [weak self] response in
                    if response.status == "SUCCESS" {
                        MendixBackwardsCompatUtility.update(response.runtimeInfo!.version)
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
    
    // MARK: - Data Clearing Methods
    public func clearData() {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        
        let filesDirectoryName = MxConfiguration.filesDirectoryName
        let filesPath = documentPath.appendingPathComponent(filesDirectoryName)
        _ = NativeFsModule.remove(filesPath.path, error: nil)
        
        RNCAsyncStorage.clearAllData()
        ReactNative.clearKeychain()
        NativeCookieModule.clearAll()
        
        let databaseName = MxConfiguration.databaseName
        let databasePath = libraryPath.appendingPathComponent("LocalDatabase/\(databaseName)")
        _ = NativeFsModule.remove(databasePath.path, error: nil)
    }
    
    // MARK: - Debugging Methods
    func remoteDebugging(_ enable: Bool) {
        showSplashScreen()
        AppPreferences.remoteDebuggingEnabled = enable
        
        let appUrl = AppPreferences.appUrl!
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
        if tapGestureRecognizer == nil {
            tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(appReloadAction(_:)))
            tapGestureRecognizer?.numberOfTouchesRequired = 3
        }
        if let tapGesture = tapGestureRecognizer {
            window.addGestureRecognizer(tapGesture)
        }
        
//        if longPressGestureRecognizer == nil {
//            longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(appMenuShowAction(_:)))
//            longPressGestureRecognizer?.numberOfTouchesRequired = 3
//        }
//        if let longPressGesture = longPressGestureRecognizer {
//            window.addGestureRecognizer(longPressGesture)
//        }
    }
    
    private func removeThreeFingerGestures(from window: UIWindow) {
        if let tapGesture = tapGestureRecognizer {
            window.removeGestureRecognizer(tapGesture)
        }
        
        if let longPressGesture = longPressGestureRecognizer {
            window.removeGestureRecognizer(longPressGesture)
        }
        
        window.motionBegan(.motionShake, with: nil)
    }
    
    @objc private func appReloadAction(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended && isActive() {
            reloadWithState()
        }
    }
    
//    @objc private func appMenuShowAction(_ gestureRecognizer: UILongPressGestureRecognizer) {
//        if gestureRecognizer.state == .began {
//            showAppMenu()
//        }
//    }
    
    public func bundleURL() -> URL? {
        return bundleUrl
    }
    
    func getRootView() -> UIView? {
        return rootViewController?.view
    }
    
    // MARK: - Legacy Methods (for compatibility)
    func useCodePush() -> Bool {
        // Implementation depends on your specific CodePush setup
        return false
    }
    
    func turboModule<T: NSObject>(type: T.Type) -> T? {
        return bridge?.moduleRegistry.module(for: type.self) as? T
    }
}

enum UnsafeMxFunction {
    
    case reloadClientWithState
    
    var name: String {
        switch self {
        case .reloadClientWithState:
            return String(describing: self)
        }
    }
    
    var selector: Selector {
        NSSelectorFromString(name)
    }
    
    var className: String {
        return "MendixNative"
    }
    
    var target: NSObject? {
        return ReactNative.instance.bridge?.moduleRegistry.module(forName: className) as? NSObject
    }
    
    func perform() {
        if let target = target, target.responds(to: selector) {
            target.perform(selector)
        } else {
            print("Failed to invoke \(selector) on \(className)")
        }
    }
}

