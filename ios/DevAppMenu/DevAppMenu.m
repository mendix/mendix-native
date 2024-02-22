#import "DevAppMenu.h"
#import <UIKit/UIKit.h>
#import <React/RCTBridge.h>
#import <React/RCTUtils.h>
#import "React/RCTRedBox.h"
#import "ReactNative.h"
#import "AppMenuProtocol.h"
#import "AppPreferences.h"
#import "UIAlertControllerExt.h"
#import "UIAlertActionExt.h"
#import "DevAppMenuUIAlertController.h"

@implementation DevAppMenu

typedef void (^ ShowAlertHandler)(UIAlertAction*);

ShowAlertHandler showAlertHandler;
ShowAlertHandler showAdvancedAlertHandler;

- (void) show:(BOOL)devMode {
    RCTBridge *bridge = [[ReactNative instance] getBridge];
    UIWindow *window = UIApplication.sharedApplication.keyWindow;

    UIAlertControllerStyle style = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone ? UIAlertControllerStyleActionSheet : UIAlertControllerStyleAlert;
    UIAlertController *alert = [DevAppMenuUIAlertController alertControllerWithTitle:@"App menu" message:nil preferredStyle:style];
    UIAlertController *advanceAlert = [DevAppMenuUIAlertController alertControllerWithTitle:@"Advance settings" message:nil preferredStyle:style];
    
    showAlertHandler = [self createShowAlert:alert completion:nil];
    showAdvancedAlertHandler = [self createShowAlert:advanceAlert completion: ^{
        [advanceAlert applyAccessibilityIdentifiers];
    }];
    
    if (devMode) {
        [self addDevModeAction:alert advancedAlert: advanceAlert];
    }
    
    UIAlertAction *reloadAction = [UIAlertAction actionWithTitle:@"Refresh" style:UIAlertActionStyleDefault handler:^void(UIAlertAction * _Nonnull action) {
        [[ReactNative instance] reload];
    }];
    [reloadAction setAccessibilityIdentifier: @"reload_button"];
    [alert addAction:reloadAction];

    UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"Return To Homescreen" style:UIAlertActionStyleDefault handler:^void(UIAlertAction * _Nonnull action) {
        if (bridge.redBox) {
            [bridge.redBox dismiss];
        }
        [[ReactNative instance] stop];
    }];
    [closeAction setAccessibilityIdentifier: @"close_button"];
    [alert addAction:closeAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
    [cancelAction setAccessibilityIdentifier: @"cancel_button"];
    [alert addAction:cancelAction];
    
    if (RCTPresentedViewController() == nil) {
        if (window != nil) {
            window.rootViewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
        }
    }
    
    if ([RCTPresentedViewController() class] != [UIAlertController class]) {
        [RCTPresentedViewController() presentViewController:alert animated:YES completion:^{
            [alert applyAccessibilityIdentifiers];
        }];
    }
}

- (void) addDevModeAction:(UIAlertController *)alert advancedAlert:(UIAlertController *)advancedAlert {
    BOOL isDebuggingRemotely = [[ReactNative instance] isDebuggingRemotely];
    
    [self addAdvanceSettingsAction:alert advancedAlert:advancedAlert];
    
    UIAlertAction *advancedSettingsAction = [UIAlertAction actionWithTitle:@"Advanced settings" style:UIAlertActionStyleDefault handler:showAdvancedAlertHandler];
    [advancedSettingsAction setAccessibilityIdentifier: @"advanced_settings_button"];
    [alert addAction:advancedSettingsAction];
    
    NSString *remoteDebuggingTitle = [(!isDebuggingRemotely ? @"Enable" : @"Disable") stringByAppendingString:@" remote JS debugging"];
    UIAlertAction *remoteDebuggingAction = [UIAlertAction actionWithTitle:remoteDebuggingTitle style:UIAlertActionStyleDefault handler:^void(UIAlertAction * _Nonnull action) {
        [[ReactNative instance] remoteDebugging:!isDebuggingRemotely];
    }];
    [remoteDebuggingAction setAccessibilityIdentifier: @"remote_debugging_button"];
    [alert addAction:remoteDebuggingAction];
    
    UIAlertAction *toggleElementInspectorAction = [UIAlertAction actionWithTitle:@"Toggle Element Inspector" style:UIAlertActionStyleDefault handler:^void(UIAlertAction * _Nonnull action) {
        [AppPreferences setElementInspector:![AppPreferences isElementInspectorEnabled]];
        [[ReactNative instance] toggleElementInspector];
    }];
    [toggleElementInspectorAction setAccessibilityIdentifier: @"toggle_inspector_button"];
    [alert addAction:toggleElementInspectorAction];
}

- (void) addAdvanceSettingsAction:(UIAlertController *)alert advancedAlert:(UIAlertController *)advancedAlert {
    UIAlertAction *clearDataButtonAction = [UIAlertAction actionWithTitle:@"Clear Data" style:UIAlertActionStyleDestructive handler:^void(UIAlertAction * _Nonnull action) {
        [[ReactNative instance] clearData];
        [[ReactNative instance] reload];
    }];
    [clearDataButtonAction setAccessibilityIdentifier: @"clear_data_button"];
    [clearDataButtonAction setEnabled:[[ReactNative instance] getBridge] != nil];
    [advancedAlert addAction:clearDataButtonAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Back" style:UIAlertActionStyleCancel handler:showAlertHandler];
    [cancelAction setAccessibilityIdentifier: @"cancel_button"];
    [advancedAlert addAction:cancelAction];
}

- (ShowAlertHandler) createShowAlert:(UIAlertController *)alert completion:(void (^)(void)) completion {
    return ^(UIAlertAction *action) {
        [RCTPresentedViewController() presentViewController:alert animated:YES completion:completion];
    };
}

@end
