#import "ReactNative.h"
#import <React/RCTBridge+Private.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTDevSettings.h>
#import <React/RCTRootView.h>
#import <React/RCTReloadCommand.h>
#import <React/RCTUtils.h>
#import <IQKeyboardManager/IQKeyboardManager.h>
#import "RNCAsyncStorage.h"
#import "AppPreferences.h"
#import "MendixReactWindow.h"
#import "MxConfiguration.h"
#import "NativeFsModule.h"
#import "NativeReloadHandler.h"
#import "AppUrl.h"
#import "RNCAsyncStorageExt.h"
#import "MendixBackwardsCompatUtility.h"
#import "RuntimeInfoProvider.h"
#import "DevAppMenuUIAlertController.h"
#import "OtaJSBundleFileProvider.h"
#import "OtaHelpers.h"

@implementation ReactNative
static ReactNative *instance = nil;

@synthesize delegate = _delegate;

UIViewController *rootViewController;
UITapGestureRecognizer *tapGestureRecognizer;
UILongPressGestureRecognizer *longPressGestureRecognizer;

+ (ReactNative *) instance {
    if (instance == nil) {
        instance = [[ReactNative alloc] init];
    }
    
    return instance;
}

+ (NSString *) warningsFilterToString:(WarningsFilter)warningsFilter {
    return WarningsFilter_toString[warningsFilter];
}

+ (NSString *)toAppScopeKey:(NSString *)key {
    NSString *appName = MxConfiguration.appName;
    return (appName && appName.length) ? [NSString stringWithFormat:@"%@_%@", appName, key] : key;
}

+ (void)clearKeychain {
    NSArray<NSString *> *keys = @[
        [ReactNative toAppScopeKey:@"token"],
        [ReactNative toAppScopeKey:@"session"]
    ];
    
    for (NSString *key in keys) {
        [self deleteKeychainItemWithKey:key];
    }
}

+ (void)deleteKeychainItemWithKey:(NSString *)key {
    NSDictionary *query = @{
        (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount : key,
        (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue
    };
    SecItemDelete((__bridge CFDictionaryRef)query);
}

- (id) init {
    if (self = [super init]) {
        rootWindow = [[UIApplication sharedApplication] keyWindow];
        rootViewController = rootWindow.rootViewController;
        codePushKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CodePushKey"] ?: @"";
    }
    return self;
}

- (NSURL *) sourceURLForBridge:(RCTBridge *)bridge {
    return self->bundleUrl;
}

- (void) setup:(MendixApp *)mendixApp launchOptions:(NSDictionary *)launchOptions {
    self->mendixApp = mendixApp;
    self->bundleUrl = mendixApp.bundleUrl;
    self->launchOptions = launchOptions;
    
    NSString *jsLocation = [NSString stringWithFormat:@"%@:%@", self->bundleUrl.host, self->bundleUrl.port];
    [[RCTBundleURLProvider sharedSettings] setJsLocation:jsLocation];
}

- (void) start {
    if (self->mendixApp == nil) {
        [NSException raise:@"MendixAppMissing" format:@"MendixApp not passed before starting the app"];
    }
    
    MxConfiguration.runtimeUrl = self->mendixApp.runtimeUrl;
    MxConfiguration.appName = self->mendixApp.identifier;
    MxConfiguration.isDeveloperApp = self->mendixApp.isDeveloperApp;
    MxConfiguration.databaseName = self->mendixApp.identifier;
    MxConfiguration.filesDirectoryName = self->mendixApp.identifier != nil ? [@"files" stringByAppendingPathComponent:self->mendixApp.identifier] : nil;
    MxConfiguration.warningsFilter = mendixApp.warningsFilter;
    MxConfiguration.codePushKey = codePushKey;
    MxConfiguration.appSessionId = [NSString stringWithFormat:@"%d%lld",arc4random_uniform(1000), (long long)([[NSDate date] timeIntervalSince1970] * 1000.0)];
    
    if (self->mendixApp.clearDataAtLaunch) {
        [self clearData];
    }

    UIViewController *appLoadingController = mendixApp.reactLoading != nil ? [mendixApp.reactLoading instantiateInitialViewController] : [[UIViewController alloc] init];
    
    bridge = [[RCTBridge alloc] initWithDelegate: (id<RCTBridgeDelegate>)self launchOptions: launchOptions];
    [[bridge devSettings] setIsShakeToShowDevMenuEnabled:NO];
    [[bridge devSettings] setIsDebuggingRemotely:[self isDebuggingRemotely]];
    
    UIView *reactRootView = [[RCTRootView alloc] initWithBridge:bridge moduleName:@"App" initialProperties:nil];
    [reactRootView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    reactRootView.frame = rootWindow.rootViewController.view.frame;
    
    rootWindow.rootViewController = appLoadingController;
    [rootWindow.rootViewController.view addSubview:reactRootView];
    [self showSplashScreen];

    if (mendixApp.isDeveloperApp || mendixApp.enableThreeFingerGestures) {
        [self attachThreeFingerGestures: rootWindow];
        RCTExecuteOnMainQueue(^{
            RCTRegisterReloadCommandListener(self);
        });
    }
    
    IQKeyboardManager.sharedManager.enable = YES;
    IQKeyboardManager.sharedManager.enableAutoToolbar = NO;
}

- (void)didReceiveReloadCommand {
    [self showSplashScreen];
}

- (void) showSplashScreen {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![MendixBackwardsCompatUtility unsupportedFeatures].hideSplashScreenInClient && self->mendixApp.splashScreenPresenter != nil) {
            [self->mendixApp.splashScreenPresenter show:[self getRootView]];
        }
    });
}

- (void) hideSplashScreen {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->mendixApp.splashScreenPresenter != nil) {
            [self->mendixApp.splashScreenPresenter hide];
        }
    });
}

- (void) reload {
    [self showSplashScreen];
    
    NSURL* otaBundleUrl = [OtaJSBundleFileProvider getBundleUrl];
    if (!mendixApp.isDeveloperApp && otaBundleUrl != nil) {
    	[bridge setValue:otaBundleUrl forKey:@"bundleURL"];
    }
    
    if (mendixApp.isDeveloperApp) {
        [RuntimeInfoProvider getRuntimeInfo:[AppUrl forRuntimeInfo:[mendixApp.runtimeUrl absoluteString]] completionHandler:^(RuntimeInfoResponse *response) {
            if ([response.status  isEqual: @"SUCCESS"]) {
                [MendixBackwardsCompatUtility update:response.runtimeInfo.version];
            }
            // Do backwards compatibility check here

            [self reloadWithBridge];
        }];
    } else {
        [self reloadWithBridge];
    }
}

- (void) reloadWithBridge {
    RCTTriggerReloadCommandListeners(@"Mendix - reload");
}

- (void) reloadWithState {
    [[[self getBridge] moduleForClass:[NativeReloadHandler class]] reloadClientWithState];
}

- (void) clearData {
    NSURL *documentPath = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] isDirectory:YES];
    NSURL *libraryPath = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0] isDirectory:YES];
    [NativeFsModule remove:[documentPath URLByAppendingPathComponent:MxConfiguration.filesDirectoryName isDirectory:YES].path error:nil];
    [self clearAsyncStorage];
    [ReactNative clearKeychain];
    [self clearCookies];
    [NativeFsModule remove:[libraryPath URLByAppendingPathComponent:[@"LocalDatabase/" stringByAppendingString:MxConfiguration.databaseName] isDirectory:YES].path error:nil];
}

- (void) clearAsyncStorage {
    [RNCAsyncStorage clearAllData];
}

- (void) clearCookies {
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray<NSHTTPCookie *> *cookies = [storage cookies];
    if (cookies == nil) {
        return;
    }
    
    for(NSHTTPCookie *cookie in cookies) {
        [storage deleteCookie:cookie];
    }
}

- (void) stop {
    [self hideSplashScreen];
    self->launchOptions = nil;

    [self->rootWindow setHidden:NO];
    [self->rootWindow makeKeyAndVisible];
    
#if DEBUG || RCT_DEBUG
    if ([AppPreferences isElementInspectorEnabled]) {
        [self toggleElementInspector];
    }
    [AppPreferences setElementInspector:NO];
#endif
    
    [bridge invalidate];
    
    IQKeyboardManager.sharedManager.enable = NO;
    
    [self removeThreeFingerGestures: rootWindow];
    rootWindow.rootViewController = rootViewController;

    [[self delegate] onAppClosed];

    [self setDelegate:nil];
    self->bridge = nil;
}

- (BOOL) isActive {
    return self->bridge != nil;
}

- (NSURL *) getJSBundleFile {
    if ([self hasNativeOtaBundle]) {
        NSURL *bundleUrl = [OtaJSBundleFileProvider getBundleUrl];
        if (bundleUrl != nil) {
            return bundleUrl;
        }
    }

    return [[NSBundle mainBundle] URLForResource:@"index.ios" withExtension:@"bundle" subdirectory:@"Bundle"];
}

- (BOOL) useCodePush {
    return self->codePushKey.length > 0;
}

- (BOOL) hasNativeOtaBundle {
    return [NSData dataWithContentsOfFile:[OtaHelpers getOtaManifestFilepath]] != nil;
}

- (void) remoteDebugging:(BOOL)enable {
    [self showSplashScreen];
    [AppPreferences remoteDebugging:enable];
    
    self->bundleUrl = [AppUrl forBundle:[AppPreferences getAppUrl] port:[AppPreferences getRemoteDebuggingPackagerPort] isDebuggingRemotely: enable isDevModeEnabled:YES];
    [[bridge devSettings] setIsDebuggingRemotely: enable];
}

- (void) setRemoteDebuggingPackagerPort:(NSInteger)port {
    [AppPreferences setRemoteDebuggingPackagerPort:port];
    [self remoteDebugging:YES];
}

- (BOOL) isDebuggingRemotely {
    return [AppPreferences devModeEnabled] && [AppPreferences remoteDebuggingEnabled];
}

- (void)showAppMenu {
    if (![RCTPresentedViewController() isKindOfClass:[DevAppMenuUIAlertController class]]) {
        [mendixApp.appMenu show:[AppPreferences devModeEnabled]];
    }
}

- (void) toggleElementInspector {
    [[bridge devSettings] toggleElementInspector];
}

- (void) attachThreeFingerGestures:(UIWindow*)window {
    if (tapGestureRecognizer == nil) {
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(appReloadAction:)];
        tapGestureRecognizer.numberOfTouchesRequired = 3;
    }
    [window addGestureRecognizer:tapGestureRecognizer];
    
    if (longPressGestureRecognizer == nil) {
        longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(appMenuShowAction:)];
        longPressGestureRecognizer.numberOfTouchesRequired = 3;
    }
    [window addGestureRecognizer:longPressGestureRecognizer];
}

- (void) removeThreeFingerGestures:(UIWindow*)window {
    if (tapGestureRecognizer != nil) {
        [window removeGestureRecognizer:tapGestureRecognizer];
    }
    
    if (longPressGestureRecognizer != nil) {
        [window removeGestureRecognizer:longPressGestureRecognizer];
    }
    
    [window motionBegan:UIEventSubtypeMotionShake withEvent: nil];
}



- (void) appReloadAction:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded && bridge != nil) {
        [self reloadWithState];
    }
}

- (void) appMenuShowAction:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self showAppMenu];
    }
}

- (RCTBridge *) getBridge {
    return bridge;
}

- (UIView * _Nullable) getRootView {
    if (rootWindow != nil) {
        return rootWindow.rootViewController.view;
    }
    return nil;
}

@end
