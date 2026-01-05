import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider
import MendixNative

@main
class AppDelegate: RCTAppDelegate {
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        self.moduleName = "App"
        self.dependencyProvider = RCTAppDependencyProvider()
        self.initialProps = [:]
        super.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        //Start - For MendixApplication compatibility only, not part of React Native template
        SessionCookieStore.restore()
        MxConfiguration.update(from:
            MendixApp.init(
                identifier: nil,
                bundleUrl: bundleURL()!,
                runtimeUrl: URL(string: "http://localhost:8081")!,
                warningsFilter: .none,
                isDeveloperApp: false,
                clearDataAtLaunch: false,
                splashScreenPresenter: nil,
                reactLoading: nil,
                enableThreeFingerGestures: false
            )
        )
        //End - For MendixApplication compatibility only, not part of React Native template
        return true
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        SessionCookieStore.persist()
    }
    
    override func applicationWillTerminate(_ application: UIApplication) {
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
