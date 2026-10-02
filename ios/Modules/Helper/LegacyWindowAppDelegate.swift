import UIKit

open class LegacyWindowAppDelegate: UIResponder, UIApplicationDelegate {
    @objc open var window: UIWindow? {
        get { ReactAppProvider.shared()?.window }
        set { ReactAppProvider.shared()?.window = newValue }
    }
}
