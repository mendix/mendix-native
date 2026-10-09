import Foundation
import React

// Main actor only. Don't hop here with main.sync: the main thread can be blocked waiting on the
// JS thread, so a JS-thread caller would deadlock. TurboModules use their injected moduleRegistry instead.
@MainActor
extension ReactHostHelper {
    static func module(for type: AnyClass) -> Any? {
        currentModuleRegistry()?.module(for: type)
    }

    static func isReactAppActive() -> Bool {
        currentModuleRegistry() != nil
    }
}
