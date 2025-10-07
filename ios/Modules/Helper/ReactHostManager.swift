import React

public class ReactHostManager {
    
    public static var bridge: RCTBridge? {
        return ReactAppProvider.shared()?.bridge
    }
    
    public static func module<T: NSObject>(type: T.Type) -> T? {
        return bridge?.moduleRegistry.module(for: type.self) as? T
    }
    
    public static func module(name: String) -> Any? {
        return bridge?.moduleRegistry.module(forName: name)
    }
    
    public static var isActive: Bool {
        return ReactAppProvider.shared()?.isReactAppActive() ?? false
    }
}

