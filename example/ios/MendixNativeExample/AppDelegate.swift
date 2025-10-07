import UIKit
import React
import MendixNative

@main
class AppDelegate: ReactAppProvider {
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        super.setUpProvider()
        super.application(application, didFinishLaunchingWithOptions: launchOptions)
        changeRoot(to: Home())
        return true
    }
    
    open override func bundleURL() -> URL? {
        return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
    }
}

class Home: UIViewController {
    
    lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Open React App", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(openApp), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc func openApp() {
        ReactAppProvider.shared()?.setReactViewController(UIViewController())
    }
}
