import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

@objcMembers
open class ReactAppProvider: UIResponder, UIWindowSceneDelegate {
    
    public static let defaultName = "App"

    public var window: UIWindow?
    public var reactNativeFactory: RCTReactNativeFactory?
    public var reactNativeDelegate: ReactNativeDelegate?
    public var moduleName: String = defaultName
    
    var reactRootViewName: String = defaultName
    
    private static weak var currentProvider: ReactAppProvider?
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
        guard reactNativeFactory == nil else {
            return
        }
        let delegate = ReactNativeDelegate()
        let factory = RCTReactNativeFactory(delegate: delegate)
        delegate.dependencyProvider = RCTAppDependencyProvider()
        reactNativeDelegate = delegate
        reactNativeFactory = factory
    }

    open func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }
        ReactAppProvider.currentProvider = self
        window = UIWindow(windowScene: windowScene)

        if let reactRootViewController = reactRootViewController {
            changeRoot(to: reactRootViewController)
        }
    }

    open func sceneDidDisconnect(_ scene: UIScene) {
        if ReactAppProvider.currentProvider === self {
            ReactAppProvider.currentProvider = nil
        }
    }

    open func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        forwardURLContextsToReact(URLContexts)
    }

    public func handleURLContexts(
        _ URLContexts: Set<UIOpenURLContext>,
        whenReactInactive: ([AnyHashable: Any]) -> Void
    ) {
        if ReactAppProvider.isReactAppActive() {
            forwardURLContextsToReact(URLContexts)
        } else if let context = URLContexts.first {
            whenReactInactive(ReactAppProvider.launchOptions(fromURLContext: context))
        }
    }

    open func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        RCTLinkingManager.application(
            UIApplication.shared,
            continue: userActivity,
            restorationHandler: { _ in }
        )
    }

    public static func launchOptions(from connectionOptions: UIScene.ConnectionOptions) -> [AnyHashable: Any] {
        var launchOptions: [AnyHashable: Any] = [:]
        if let context = connectionOptions.urlContexts.first {
            launchOptions.merge(ReactAppProvider.launchOptions(fromURLContext: context)) { _, new in new }
        }
        if let userActivity = connectionOptions.userActivities.first {
            launchOptions[UIApplication.LaunchOptionsKey.userActivityDictionary] = [
                UIApplication.LaunchOptionsKey.userActivityType: userActivity.activityType,
                "UIApplicationLaunchOptionsUserActivityKey": userActivity
            ] as [AnyHashable: Any]
        }
        return launchOptions
    }

    public static func launchOptions(fromURLContext context: UIOpenURLContext) -> [AnyHashable: Any] {
        var launchOptions: [AnyHashable: Any] = [
            UIApplication.LaunchOptionsKey.url: context.url
        ]
        launchOptions[UIApplication.LaunchOptionsKey.sourceApplication] = context.options.sourceApplication
        launchOptions[UIApplication.LaunchOptionsKey.annotation] = context.options.annotation
        return launchOptions
    }

    private func forwardURLContextsToReact(_ URLContexts: Set<UIOpenURLContext>) {
        URLContexts.forEach { context in
            var options: [UIApplication.OpenURLOptionsKey: Any] = [
                .openInPlace: context.options.openInPlace
            ]
            options[.sourceApplication] = context.options.sourceApplication
            options[.annotation] = context.options.annotation
            RCTLinkingManager.application(UIApplication.shared, open: context.url, options: options)
        }
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
        view.frame = window?.bounds ?? .zero
        return view
    }

    public func startReactApp() {
        reactNativeFactory?.startReactNative(withModuleName: moduleName, in: window)
    }
    
    public func stopReactApp() {
    }
    
    public static func shared() -> ReactAppProvider? {
        return currentProvider
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
