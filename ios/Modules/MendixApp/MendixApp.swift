import UIKit

public class MendixApp: NSObject {
    public let bundleUrl: URL
    public let runtimeUrl: URL
    public let warningsFilter: WarningsFilter
    public let identifier: String?
    public let isDeveloperApp: Bool
    public let clearDataAtLaunch: Bool
    public let splashScreenPresenter: SplashScreenPresenterProtocol?
    public let reactLoading: UIStoryboard?
    public var enableThreeFingerGestures: Bool = false
    
    public init(
        identifier: String?,
        bundleUrl: URL,
        runtimeUrl: URL,
        warningsFilter: WarningsFilter,
        isDeveloperApp: Bool,
        clearDataAtLaunch: Bool,
        splashScreenPresenter: SplashScreenPresenterProtocol?,
        reactLoading: UIStoryboard?,
        enableThreeFingerGestures: Bool
    ) {
        self.bundleUrl = bundleUrl
        self.runtimeUrl = runtimeUrl
        self.warningsFilter = warningsFilter
        self.identifier = identifier
        self.isDeveloperApp = isDeveloperApp
        self.clearDataAtLaunch = clearDataAtLaunch
        self.splashScreenPresenter = splashScreenPresenter
        self.reactLoading = reactLoading
        self.enableThreeFingerGestures = enableThreeFingerGestures
    }
}
//Checked
