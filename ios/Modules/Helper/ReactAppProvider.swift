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
        reactNativeFactory?.startReactNative(withModuleName: moduleName, in: window)
    }
    
    public func stopReactApp() {
    }
    
    public static func shared() -> ReactAppProvider? {
        if Thread.isMainThread {
            return UIApplication.shared.delegate as? ReactAppProvider
        } else {
            return DispatchQueue.main.sync {
                return UIApplication.shared.delegate as? ReactAppProvider
            }
        }
    }

    public func changeRoot(to controller: UIViewController) {
        window?.rootViewController = controller
        window?.makeKeyAndVisible()
    }

    public var rootView: UIView? {
        return window?.rootViewController?.view
    }

    public static func isReactAppActive() -> Bool {
        return shared()?.reactHost() != nil
    }
    
    public func reactHost() -> RCTHost? {
        return reactNativeFactory?.rootViewFactory.reactHost
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
