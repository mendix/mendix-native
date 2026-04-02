import UIKit
import React
import MendixNative

@main
class AppDelegate: ReactAppProvider {
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        setUpProvider()
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
    
    var bundleUrl: URL {
#if DEBUG
        RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")!
#else
        Bundle.main.url(forResource: "main", withExtension: "jsbundle")!
#endif
    }
}
