import Foundation

public class UnsupportedFeatures: NSObject {
    public let reloadInClient: Bool
    public let hideSplashScreenInClient: Bool
    
    public init(reloadInClient: Bool, hideSplashScreenInClient: Bool = false) {
        self.reloadInClient = reloadInClient
        self.hideSplashScreenInClient = hideSplashScreenInClient
        super.init()
    }
}
