#import "MxCookie.h"
#import "RCTAppDelegate.h"
#import <React/RCTReloadCommand.h>
#import "MendixNative-Swift.h"

@implementation MxCookie

RCT_EXPORT_MODULE()

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMxCookieSpecJSI>(params);
}

- (void)clearAll:(nonnull RCTPromiseResolveBlock)resolve
          reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [Promise instance:resolve reject:reject];
    [[[NativeCookieModule alloc] init] clearAll:promise];
}

@end
