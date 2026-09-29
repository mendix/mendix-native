import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

@objcMembers
open class ReactAppProvider: UIResponder, UIApplicationDelegate {
    
    public static let defaultName = "App"

    public var window: UIWindow?
    public var reactNativeFactory: RCTReactNativeFactory?
    public var reactNativeDelegate: ReactNativeDelegate?
    public var moduleName: String = defaultName
    
    var reactRootViewName: String = defaultName

    private var reactRootViewController: UIViewController?

    public var hasStartedReact: Bool {
        return reactRootViewController != nil
    }

    public func setUpProvider(
        moduleName: String = ReactAppProvider.defaultName,
        reactRootViewName: String = ReactAppProvider.defaultName
    ) {
        self.moduleName = moduleName
        self.reactRootViewName = reactRootViewName
        let delegate = ReactNativeDelegate()
        let factory = RCTReactNativeFactory(delegate: delegate)
        delegate.dependencyProvider = RCTAppDependencyProvider()
        reactNativeDelegate = delegate
        reactNativeFactory = factory
        window = UIWindow(frame: UIScreen.main.bounds)
    }
    
    open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
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
        guard let view = reactNativeFactory?.rootViewFactory.view(
            withModuleName: reactRootViewName,
            initialProperties: nil,
            launchOptions: launchOptions
        ) else {
            return nil
        }
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.frame = window?.rootViewController?.view.frame ?? .zero
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
        reactNativeFactory?.startReactNative(withModuleName: moduleName, in: window)
    }
    
    public func stopReactApp() {
    }
    
    public static func shared() -> ReactAppProvider? {
        return UIApplication.shared.delegate as? ReactAppProvider
    }

    public func changeRoot(to controller: UIViewController) {
        window?.rootViewController = controller
        window?.makeKeyAndVisible()
    }

    public var rootView: UIView? {
        return window?.rootViewController?.view
    }

    public static func isReactAppActive() -> Bool {
        return ReactHostHelper().isReactAppActive()
    }
}


public class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
    public override func sourceURL(for bridge: RCTBridge) -> URL? {
        self.bundleURL()
    }

    public override func bundleURL() -> URL? {
        return ReactNative.shared.bundleURL()
    }
}
