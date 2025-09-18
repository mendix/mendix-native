//import UIKit
//import ObjectiveC
//
//extension UIAlertAction {
//    private static var associatedIdentifierKey: UInt8 = 0 //TODO: verify this
//    
//    @objc public func setAccessibilityIdentifier(_ accessibilityIdentifier: String) {
//        objc_setAssociatedObject(self, &UIAlertAction.associatedIdentifierKey, accessibilityIdentifier, .OBJC_ASSOCIATION_RETAIN)
//    }
//    
//    @objc public func getAccessibilityIdentifier() -> String? {
//        return objc_getAssociatedObject(self, &UIAlertAction.associatedIdentifierKey) as? String
//    }
//}
