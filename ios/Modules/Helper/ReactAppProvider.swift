import UIKit
import React
import React_RCTAppDelegate

open class ReactAppProvider: RCTDefaultReactNativeFactoryDelegate, UIApplicationDelegate {
    
    public static let defaultName = "App"

    public var window: UIWindow?
    public var reactNativeFactory: RCTReactNativeFactory?
    public var moduleName: String = defaultName
    
    var reactRootViewName: String = defaultName
    
    public func setUpProvider(
        moduleName: String = ReactAppProvider.defaultName,
        reactRootViewName: String = ReactAppProvider.defaultName,
        dependencyProvider: (any RCTDependencyProvider)? = nil
    ) {
        self.moduleName = moduleName
        self.reactRootViewName = reactRootViewName
        if let dependencyProvider {
            self.dependencyProvider = dependencyProvider
        }
        window = MendixReactWindow(frame: UIScreen.main.bounds)
        reactNativeFactory = RCTReactNativeFactory(delegate: self)
    }

    open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        true
    }
    
    open override func bundleURL() -> URL? {
        return ReactNative.shared.bundleURL()
    }

    open override func sourceURL(for bridge: RCTBridge) -> URL? {
        return self.bundleURL()
    }
    
    public func setReactViewController(_ controller: UIViewController) {
        controller.view = reactAppView()
        changeRoot(to: controller)
    }
    
    public func reactAppView() -> UIView? {
        guard let view = reactNativeFactory?.rootViewFactory.view(withModuleName: reactRootViewName) else {
            return nil
        }
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.frame = window?.rootViewController?.view.frame ?? .zero
        return view
    }
    
    public func startReactApp() {
        
    }
    
    public func stopReactApp() {
    }
    
    public static func shared() -> ReactAppProvider? {
        return UIApplication.shared.delegate as? ReactAppProvider
    }
    
    public static func isReactAppActive() -> Bool {
        return unsafeBridge != nil
    }
    
    public func changeRoot(to controller: UIViewController) {
        window?.rootViewController = controller
        window?.makeKeyAndVisible()
    }
    
    public var rootView: UIView? {
        return window?.rootViewController?.view
    }
    
    public static func getModule<T: NSObject>(type: T.Type) -> T? {
        return unsafeBridge?.moduleRegistry.module(for: type.self) as? T
    }
        
    public static func getModule(name: String) -> Any? {
        return unsafeBridge?.moduleRegistry.module(forName: name)
    }
    
    public static var unsafeBridge: RCTBridge? {
        return RCTBridge.current()
    }
}
