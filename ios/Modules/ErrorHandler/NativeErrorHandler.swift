import Foundation
import React

@objcMembers
public class NativeErrorHandler: NSObject {
    public func handle(message: String, stackTrace: [[String: Any]]) {
        DevHelper.getModule(type: RCTExceptionsManager.self)?.reportFatalException(message, stack: stackTrace, exceptionId: -1)
    }
}
