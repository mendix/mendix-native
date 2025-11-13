import Foundation
import React

final class RedBoxHelper {
    
    static let shared = RedBoxHelper()
    
    let redBox: RCTRedBox = RCTRedBox()
    
    private init() {}
}
