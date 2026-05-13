import UIKit
import React
import MendixNative
import React_RCTAppDelegate
import ReactAppDependencyProvider

@main
class AppDelegate: ReactAppProvider {
    
    var reactNativeDelegate: ReactNativeDelegate?
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        
        let delegate = ReactNativeDelegate()
        let factory = RCTReactNativeFactory(delegate: delegate)
        delegate.dependencyProvider = RCTAppDependencyProvider()

        reactNativeDelegate = delegate
        
        setUpProvider(reactNativeFactory: factory)
        guard let bundleUrl = bundleUrl else {
            fatalError("Unable to find index.js")
        }
        let mendixApp = MendixApp.init(
            identifier: nil,
            bundleUrl: bundleUrl,
            runtimeUrl: URL(string: "http://localhost:8081")!,
            warningsFilter: .none,
            isDeveloperApp: false,
            clearDataAtLaunch: false,
            splashScreenPresenter: nil,
            reactLoading: nil,
            enableThreeFingerGestures: false
        )
        ReactNative.shared.setup(mendixApp, launchOptions: nil)
        ReactNative.shared.start()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
//    
    var bundleUrl: URL? {
#if DEBUG
        RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
        Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
    }
}


class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
  override func sourceURL(for bridge: RCTBridge) -> URL? {
    self.bundleURL()
  }

  override func bundleURL() -> URL? {
#if DEBUG
    RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
    Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
  }
}
