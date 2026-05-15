#import "MxEncryption.h"
#import "RCTAppDelegate.h"
#import <React/RCTReloadCommand.h>
#import "MendixNative-Swift.h"

@implementation MxEncryption

RCT_EXPORT_MODULE()

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMxEncryptionSpecJSI>(params);
}

- (void)setItem:(nonnull NSString *)key
          value:(nonnull NSString *)value
        resolve:(nonnull RCTPromiseResolveBlock)resolve
         reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [[Promise alloc] initWithResolve:resolve reject:reject];
    [[[EncryptedStorage alloc] init] setItemWithKey:key value:value promise:promise];
}

- (void)getItem:(nonnull NSString *)key
        resolve:(nonnull RCTPromiseResolveBlock)resolve
         reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [[Promise alloc] initWithResolve:resolve reject:reject];
    [[[EncryptedStorage alloc] init] getItemWithKey:key promise:promise];
}

- (void)removeItem:(nonnull NSString *)key
           resolve:(nonnull RCTPromiseResolveBlock)resolve
            reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [[Promise alloc] initWithResolve:resolve reject:reject];
    [[[EncryptedStorage alloc] init] removeItemWithKey:key promise:promise];
}

- (void)clear:(nonnull RCTPromiseResolveBlock)resolve
       reject:(nonnull RCTPromiseRejectBlock)reject {
    Promise *promise = [[Promise alloc] initWithResolve:resolve reject:reject];
    [[[EncryptedStorage alloc] init] clearWithPromise:promise];
}

- (nonnull NSNumber *)isEncrypted {
    return [NSNumber numberWithBool: [EncryptedStorage isEncrypted]];
}

@end
