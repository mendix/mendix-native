import UIKit
import React
import MendixNative

@main
class AppDelegate: ReactAppProvider {
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        setUpProvider()
        guard let bundleUrl = bundleURL() else {
            let message = "No script URL provided. Make sure the metro packager is running or you have embedded a JS bundle in your application bundle."
            fatalError(message)
        }
        let mendixApp = MendixApp.init(
            identifier: nil,
            bundleUrl: bundleUrl,
            runtimeUrl: URL(string: "http://localhost:8081")!,
            warningsFilter: .none,
            isDeveloperApp: true,
            clearDataAtLaunch: false,
            splashScreenPresenter: nil,
            reactLoading: nil,
            enableThreeFingerGestures: false
        )
        
        AppPreferences.devModeEnabled = true
        AppPreferences.remoteDebuggingEnabled = true
        
        ReactNative.shared.setup(mendixApp, launchOptions: nil)
        ReactNative.shared.start()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func bundleURL() -> URL? {
        #if DEBUG
            RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
        #else
            Bundle.main.url(forResource: "main", withExtension: "jsbundle")
        #endif
    }
}
