import Foundation

@objc public protocol SplashScreenPresenterProtocol: AnyObject {
    @objc func show(_ rootView: UIView?)
    @objc func hide()
}

@objcMembers public class MendixSplashScreen: NSObject {
    
    // Called from the TurboModule's method queue; presenters touch UIKit, so hop to main.
    public func show() {
        DispatchQueue.main.async {
            ReactNative.shared.showSplashScreen()
        }
    }
    
    public func hide() {
        DispatchQueue.main.async {
            ReactNative.shared.hideSplashScreen()
        }
    }
}
