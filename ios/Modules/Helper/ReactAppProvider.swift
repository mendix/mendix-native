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

    public func setReactViewController(_ controller: UIViewController) {
        controller.view = reactAppView()
        reactRootViewController = controller
        changeRoot(to: controller)
    }

    public func reactAppView() -> UIView? {
        guard let view = reactNativeFactory?.rootViewFactory.view(withModuleName: reactRootViewName) else {
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
