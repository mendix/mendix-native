//import UIKit
//import React
//import React_RCTAppDelegate
//
//@objc class DevAppMenu: NSObject, AppMenuProtocol {
//    
//    // MARK: - Type Aliases
//    typealias ShowAlertHandler = (UIAlertAction) -> Void
//    
//    // MARK: - Private Properties
//    private var showAlertHandler: ShowAlertHandler?
//    private var showAdvancedAlertHandler: ShowAlertHandler?
//    
//    // MARK: - AppMenuProtocol Implementation
//    @objc func show(_ devMode: Bool) {
////        let redbox = RedBoxHelper.shared.redBox
//        
//        let window = UIApplication.shared.connectedScenes
//            .first {$0.activationState == .foregroundActive}
//            .flatMap{ $0 as? UIWindowScene }?
//            .windows
//            .first { $0.isKeyWindow }
//        
//        let style: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .phone ? .actionSheet : .alert
//        let alert = DevAppMenuUIAlertController(title: "App menu", message: nil, preferredStyle: style)
//        let advanceAlert = DevAppMenuUIAlertController(title: "Advance settings", message: nil, preferredStyle: style)
//        
//        showAlertHandler = createShowAlert(alert, completion: nil)
//        showAdvancedAlertHandler = createShowAlert(advanceAlert) {
//            advanceAlert.applyAccessibilityIdentifiers()
//        }
//        
//        if devMode {
//            addDevModeAction(alert, advancedAlert: advanceAlert)
//        }
//        
//        // Refresh Action
//        let reloadAction = UIAlertAction(title: "Refresh", style: .default) { _ in
//            ReactNative.instance.reload()
//        }
//        reloadAction.setAccessibilityIdentifier("reload_button")
//        alert.addAction(reloadAction)
//        
//        // Return To Homescreen Action
////        let closeAction = UIAlertAction(title: "Return To Homescreen", style: .default) { _ in
////            redbox.dismiss()
////            ReactNative.instance.stop()
////        }
////        closeAction.setAccessibilityIdentifier("close_button")
////        alert.addAction(closeAction)
////        
//        // Cancel Action
//        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
//        cancelAction.setAccessibilityIdentifier("cancel_button")
//        alert.addAction(cancelAction)
//        
//        // Present the alert
//        
//        let presentedVC = RCTPresentedViewController()
//        
//        if presentedVC == nil {
//            if let window {
//                window.rootViewController = UIViewController(nibName: nil, bundle: nil)
//            }
//        }
//        
//        if type(of: presentedVC) != UIAlertController.self {
//            presentedVC?.present(alert, animated: true) {
//                alert.applyAccessibilityIdentifiers()
//            }
//        }
//    }
//    
//    // MARK: - Private Methods
//    private func addDevModeAction(_ alert: UIAlertController, advancedAlert: UIAlertController) {
//        let isDebuggingRemotely = ReactNative.instance.isDebuggingRemotely()
//        
//        addAdvanceSettingsAction(alert, advancedAlert: advancedAlert)
//        
//        // Advanced Settings Action
//        let advancedSettingsAction = UIAlertAction(title: "Advanced settings", style: .default, handler: showAdvancedAlertHandler)
//        advancedSettingsAction.setAccessibilityIdentifier("advanced_settings_button")
//        alert.addAction(advancedSettingsAction)
//        
//        // Remote Debugging Action
//        let remoteDebuggingTitle = "\(isDebuggingRemotely ? "Disable" : "Enable") remote JS debugging"
//        let remoteDebuggingAction = UIAlertAction(title: remoteDebuggingTitle, style: .default) { _ in
//            ReactNative.instance.remoteDebugging(!isDebuggingRemotely)
//        }
//        remoteDebuggingAction.setAccessibilityIdentifier("remote_debugging_button")
//        alert.addAction(remoteDebuggingAction)
//        
//        // Toggle Element Inspector Action
//        let toggleElementInspectorAction = UIAlertAction(title: "Toggle Element Inspector", style: .default) { _ in
//            AppPreferences.elementInspectorEnabled.toggle()
//            ReactNative.instance.toggleElementInspector()
//        }
//        toggleElementInspectorAction.setAccessibilityIdentifier("toggle_inspector_button")
//        alert.addAction(toggleElementInspectorAction)
//    }
//    
//    private func addAdvanceSettingsAction(_ alert: UIAlertController, advancedAlert: UIAlertController) {
//        // Clear Data Action
//        let clearDataButtonAction = UIAlertAction(title: "Clear Data", style: .destructive) { _ in
//            ReactNative.instance.clearData()
//            ReactNative.instance.reload()
//        }
//        clearDataButtonAction.setAccessibilityIdentifier("clear_data_button")
//        clearDataButtonAction.isEnabled = RCTBridge.current() != nil
//        advancedAlert.addAction(clearDataButtonAction)
//        
//        // Back Action
//        let cancelAction = UIAlertAction(title: "Back", style: .cancel, handler: showAlertHandler)
//        cancelAction.setAccessibilityIdentifier("cancel_button")
//        advancedAlert.addAction(cancelAction)
//    }
//    
//    private func createShowAlert(_ alert: UIAlertController, completion: (() -> Void)?) -> ShowAlertHandler {
//        return { _ in
//            RCTPresentedViewController()?.present(alert, animated: true, completion: completion)
//        }
//    }
//}
//
////Checked
