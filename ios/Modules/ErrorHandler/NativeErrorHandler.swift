import Foundation
import React

@objcMembers
public class NativeErrorHandler: NSObject {
    private let exceptionsManager: RCTExceptionsManager?
    
    public init(exceptionsManager: RCTExceptionsManager?) {
        self.exceptionsManager = exceptionsManager
        super.init()
    }
    
    public override convenience init() {
        self.init(exceptionsManager: nil)
    }
    
    public func handle(message: String, stackTrace: [[String: Any]]) {
        exceptionsManager?.reportFatalException(message, stack: stackTrace, exceptionId: -1)
    }
}
