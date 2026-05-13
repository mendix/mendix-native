import UIKit
import React
import React_RCTAppDelegate

@objcMembers
open class ReactAppProvider: UIResponder, UIApplicationDelegate {
    
    public static let defaultName = "App"

    public var window: UIWindow?
    public var reactNativeFactory: RCTReactNativeFactory?
    public var moduleName: String = defaultName
    
    var reactRootViewName: String = defaultName
    
    public func setUpProvider(
        moduleName: String = ReactAppProvider.defaultName,
        reactRootViewName: String = ReactAppProvider.defaultName,
        reactNativeFactory: RCTReactNativeFactory?
    ) {
        self.moduleName = moduleName
        self.reactRootViewName = reactRootViewName
        self.reactNativeFactory = reactNativeFactory
        window = MendixReactWindow(frame: UIScreen.main.bounds)
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
        return ReactHostHelper().isReactAppActive()
    }

    public static func getModule<T: NSObject>(name:String, type: T.Type) -> T? {
        return ReactHostHelper().module(forName: name) as? T
    }
}
