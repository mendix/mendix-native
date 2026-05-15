#import "MxSplashScreen.h"
#import "RCTAppDelegate.h"
#import <React/RCTReloadCommand.h>
#import "MendixNative-Swift.h"

@implementation MxSplashScreen

RCT_EXPORT_MODULE()

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMxSplashScreenSpecJSI>(params);
}

- (void)show {
    [[[MendixSplashScreen alloc] init] show];
}

- (void)hide {
    [[[MendixSplashScreen alloc] init] hide];
}

@end
