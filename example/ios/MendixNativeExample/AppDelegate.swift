import UIKit
import React
import MendixNative

@main
class AppDelegate: ReactNative {
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        super.application(application, didFinishLaunchingWithOptions: launchOptions)
        changeRoot(to: Home())
        return true
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
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let reactRootView = appDelegate.rootViewFactory.view(withModuleName: "MendixNativeExample")
        let controller = UIViewController()
        controller.view = reactRootView
        appDelegate.changeRoot(to: controller)
    }
}
