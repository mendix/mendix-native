#import "MxOta.h"
#import "RCTAppDelegate.h"
#import <React/RCTReloadCommand.h>
#import "MendixNative-Swift.h"

@implementation MxOta

RCT_EXPORT_MODULE()

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMxOtaSpecJSI>(params);
}

- (void)download:(nonnull NSDictionary *)config
         resolve:(nonnull RCTPromiseResolveBlock)resolve
          reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [Promise instance:resolve reject:reject];
    [[[NativeOtaModule alloc] init] download:config promise:promise];
}

- (void)deploy:(nonnull NSDictionary *)config
       resolve:(nonnull RCTPromiseResolveBlock)resolve
        reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [Promise instance:resolve reject:reject];
    [[[NativeOtaModule alloc] init] deploy:config promise:promise];
}

@end
