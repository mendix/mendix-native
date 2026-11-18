#import "MxEncryption.h"
#import "RCTAppDelegate.h"
#import <React/RCTReloadCommand.h>
#import <Security/Security.h>
#import "MendixNative-Swift.h"

@implementation MxEncryption

+ (NSString *)moduleName {
    return @"MxEncryption";
}

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

- (NSString *)getRandomHex:(double)byteLength {
    static const NSUInteger maxRandomBytes = 1024;
    NSUInteger length = (NSUInteger)byteLength;
    if (byteLength != (double)length || length < 1 || length > maxRandomBytes) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"byteLength must be an integer between 1 and 1024"
                                     userInfo:nil];
    }

    NSMutableData *data = [NSMutableData dataWithLength:length];
    int status = SecRandomCopyBytes(kSecRandomDefault, length, data.mutableBytes);
    if (status != errSecSuccess) {
        @throw [NSException exceptionWithName:@"MxEncryptionRandomError"
                                       reason:[NSString stringWithFormat:@"SecRandomCopyBytes failed with status %d", status]
                                     userInfo:nil];
    }

    NSMutableString *hex = [NSMutableString stringWithCapacity:length * 2];
    const uint8_t *bytes = static_cast<const uint8_t *>(data.bytes);
    for (NSUInteger i = 0; i < length; i++) {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    return hex;
}

@end
