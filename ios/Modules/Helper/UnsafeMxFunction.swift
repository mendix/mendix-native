import Foundation

enum UnsafeMxFunction {
    
    case reloadClientWithState
    
    var name: String {
        switch self {
        case .reloadClientWithState:
            return String(describing: self)
        }
    }
    
    var selector: Selector {
        NSSelectorFromString(name)
    }
    
    var className: String {
        return "MendixNative"
    }
    
    var target: NSObject? {
        return ReactAppProvider.getModule(name: className) as? NSObject
    }
    
    func perform() {
        if let target = target, target.responds(to: selector) {
            target.perform(selector)
        } else {
            print("Failed to invoke \(selector) on \(className)")
        }
    }
}
