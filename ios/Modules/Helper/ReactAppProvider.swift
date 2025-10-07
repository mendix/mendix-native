import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

open class ReactAppProvider: RCTAppDelegate {
    
    var reactRootViewName: String = "App"
    
    public func setUpProvider(moduleName: String = "App", reactRootViewName: String = "App") {
        self.moduleName = moduleName
        self.reactRootViewName = reactRootViewName
        automaticallyLoadReactNativeWindow = false
        dependencyProvider = RCTAppDependencyProvider()
        initialProps = [:]
        window = UIApplication
            .shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first { $0.isKeyWindow } ?? UIWindow(frame: UIScreen.main.bounds)
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
    
    public func isReactAppActive() -> Bool {
        return bridge != nil
    }
    
    public func changeRoot(to controller: UIViewController) {
        window.rootViewController = controller
        window.makeKeyAndVisible()
    }
    
    public var rootView: UIView? {
        return window.rootViewController?.view
    }
}
