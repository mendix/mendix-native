import Foundation

@objc public protocol SplashScreenPresenterProtocol: AnyObject {
    @objc func show(_ rootView: UIView?)
    @objc func hide()
}

@objcMembers public class MendixSplashScreen: NSObject {
  
  public func show() {
    ReactNative.instance.showSplashScreen()
  }
  
  public func hide() {
    ReactNative.instance.hideSplashScreen()
  }
}

//Checked
