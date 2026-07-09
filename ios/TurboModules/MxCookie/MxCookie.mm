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

#if DEBUG
- (void)seedTestCookies:(double)count valueSize:(double)valueSize
               resolve:(nonnull RCTPromiseResolveBlock)resolve
                reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [Promise instance:resolve reject:reject];
    [[[NativeCookieModule alloc] init] seedTestCookiesWithCount:(NSInteger)count
                                                      valueSize:(NSInteger)valueSize
                                                        promise:promise];
}

- (void)persistSessionCookies:(nonnull RCTPromiseResolveBlock)resolve
                        reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [Promise instance:resolve reject:reject];
    [[[NativeCookieModule alloc] init] persistSessionCookies:promise];
}

- (void)clearHTTPCookies:(nonnull RCTPromiseResolveBlock)resolve
                   reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [Promise instance:resolve reject:reject];
    [[[NativeCookieModule alloc] init] clearHTTPCookies:promise];
}

- (void)restoreSessionCookies:(nonnull RCTPromiseResolveBlock)resolve
                        reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [Promise instance:resolve reject:reject];
    [[[NativeCookieModule alloc] init] restoreSessionCookies:promise];
}

- (void)getKeychainChunkCount:(nonnull RCTPromiseResolveBlock)resolve
                        reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [Promise instance:resolve reject:reject];
    [[[NativeCookieModule alloc] init] getKeychainChunkCount:promise];
}
#endif

@end
