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

    public func changeRoot(to controller: UIViewController) {
        window?.rootViewController = controller
        window?.makeKeyAndVisible()
    }

    public var rootView: UIView? {
        return window?.rootViewController?.view
    }

    // Check if React Native app is active and running
    public static func isReactAppActive() -> Bool {
        return RCTBridge.current() != nil
    }

    // Dev-only module access (RCTDevMenu, RCTDevSettings, RCTDevLoadingView)
    // These modules are not TurboModules and are only available in DEV mode
    // Using optional RCTBridge.current() - returns nil gracefully when bridge unavailable
    // Note: In RN 0.83+, dev modules may not be available if using new architecture exclusively
    public static func getModule<T: NSObject>(type: T.Type) -> T? {
        return RCTBridge.current()?.moduleRegistry.module(for: type.self) as? T
    }

    public static func getModule(name: String) -> Any? {
        return RCTBridge.current()?.moduleRegistry.module(forName: name)
    }
}
