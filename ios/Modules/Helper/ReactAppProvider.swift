import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

open class ReactAppProvider: RCTAppDelegate {
    
    public static let defaultName = "App"
    
    var reactRootViewName: String = defaultName
    
    private var reactRootViewController: UIViewController?

    public var hasStartedReact: Bool {
        return reactRootViewController != nil
    }

    public func setUpProvider(moduleName: String = ReactAppProvider.defaultName, reactRootViewName: String = ReactAppProvider.defaultName) {
        self.moduleName = moduleName
        self.reactRootViewName = reactRootViewName
        automaticallyLoadReactNativeWindow = false
        dependencyProvider = RCTAppDependencyProvider()
        window = MendixReactWindow(frame: UIScreen.main.bounds)
    }
    
    public override func sourceURL(for bridge: RCTBridge) -> URL? {
        return self.bundleURL()
    }
    
    open override func bundleURL() -> URL? {
        return ReactNative.shared.bundleURL()
    }
    
    public func setReactViewController(_ controller: UIViewController) {
        setReactViewController(controller, launchOptions: nil)
    }

    public func setReactViewController(_ controller: UIViewController, launchOptions: [AnyHashable: Any]?) {
        controller.view = reactAppView(launchOptions: launchOptions)
        reactRootViewController = controller
        changeRoot(to: controller)
    }
    
    public func reactAppView() -> UIView? {
        return reactAppView(launchOptions: nil)
    }

    public func reactAppView(launchOptions: [AnyHashable: Any]?) -> UIView? {
        let view = rootViewFactory().view(
            withModuleName: reactRootViewName,
            initialProperties: nil,
            launchOptions: launchOptions
        )
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.frame = window.rootViewController?.view.frame ?? .zero
        return view
    }

    public static func launchOptions(
        from url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> [AnyHashable: Any] {
        var launchOptions: [AnyHashable: Any] = [
            UIApplication.LaunchOptionsKey.url: url
        ]
        launchOptions[UIApplication.LaunchOptionsKey.sourceApplication] = options[.sourceApplication]
        launchOptions[UIApplication.LaunchOptionsKey.annotation] = options[.annotation]
        return launchOptions
    }

    public static func launchOptions(from userActivity: NSUserActivity) -> [AnyHashable: Any] {
        return [
            UIApplication.LaunchOptionsKey.userActivityDictionary: [
                UIApplication.LaunchOptionsKey.userActivityType: userActivity.activityType,
                "UIApplicationLaunchOptionsUserActivityKey": userActivity
            ] as [AnyHashable: Any]
        ]
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
        window.rootViewController = controller
        window.makeKeyAndVisible()
    }
    
    public var rootView: UIView? {
        return window.rootViewController?.view
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
