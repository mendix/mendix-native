import UIKit
import React
import MendixNative

@main
class AppDelegate: ReactAppProvider {
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        SessionCookieStore.restore()
        setUpProvider()
        
        guard let bundleUrl = bundleURL() else {
            let message = "No script URL provided. Make sure the metro packager is running or you have embedded a JS bundle in your application bundle."
            NativeErrorHandler().handle(message: message, stackTrace: [])
            return false
        }
        
        ReactNative.shared.setup(
            MendixApp.init(
                identifier: nil,
                bundleUrl: bundleUrl,
                runtimeUrl: URL(string: "http://localhost:8081")!,
                warningsFilter: .none,
                isDeveloperApp: false,
                clearDataAtLaunch: false,
                splashScreenPresenter: nil,
                reactLoading: nil,
                enableThreeFingerGestures: false
            ),
            launchOptions: launchOptions
        )
        ReactNative.shared.start()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        SessionCookieStore.persist()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        SessionCookieStore.persist()
    }
    
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
