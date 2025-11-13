import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

open class ReactAppProvider: RCTAppDelegate {
    
    public static let defaultName = "App"
    
    var reactRootViewName: String = defaultName
    
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
        controller.view = reactAppView()
        changeRoot(to: controller)
    }
    
    public func reactAppView() -> UIView? {
        let view = rootViewFactory.view(withModuleName: reactRootViewName)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.frame = window.rootViewController?.view.frame ?? .zero
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
