import Foundation

@objcMembers
public class ReloadHandler: NSObject {
  
  public func reload() {
    DispatchQueue.main.async {
      ReactNative.instance.reload()
    }
  }
  
  public func exitApp() {
    exit(0)
  }
}

//Checked
