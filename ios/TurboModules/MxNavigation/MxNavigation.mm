#import "MxNavigation.h"
#import "RCTAppDelegate.h"
#import <React/RCTReloadCommand.h>
#import "MendixNative-Swift.h"

@implementation MxNavigation

RCT_EXPORT_MODULE()

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMxNavigationSpecJSI>(params);
}

- (nonnull NSNumber *)isNavigationBarActive {
    return [NSNumber numberWithBool:NO];
}

- (nonnull NSNumber *)getNavigationBarHeight {
    return [NSNumber numberWithDouble:0.0];
}

@end
