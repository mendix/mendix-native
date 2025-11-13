import Foundation

@objcMembers
public class NativeCookieModule: NSObject {
    public func clearAll(_ promise: Promise) {
        NativeCookieModule.clearAll()
        promise.resolve(nil)
    }
    
    static func clearAll() {
        let storage = HTTPCookieStorage.shared
        for cookie in (storage.cookies ?? []) {
            storage.deleteCookie(cookie)
        }
    }
}
