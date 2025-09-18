import Foundation

@objcMembers
public class NativeErrorHandler: NSObject {
    public func handle(message: String, stackTrace: [[String: Any]]) {
        RedBoxHelper.shared.redBox.showErrorMessage(message, withStack: stackTrace)
    }
}
//Checked
