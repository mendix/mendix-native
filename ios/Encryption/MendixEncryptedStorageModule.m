#import "MendixEncryptedStorageModule.h"
#import <Security/Security.h>

@implementation MendixEncryptedStorageModule

+ (BOOL)requiresMainQueueSetup {
    return NO;
}

- (void)rejectPromise:(NSString *)message :(NSError *)error :(RCTPromiseRejectBlock)rejecter {
    NSString *errorCode = [NSString stringWithFormat:@"%ld", error.code];
    NSString *errorMessage =
        [NSString stringWithFormat:@"RNEncryptedStorageError: %@", message];

    rejecter(errorCode, errorMessage, error);
}

RCT_EXPORT_MODULE(RNMendixEncryptedStorage);

RCT_EXPORT_METHOD(setItem
                  : (NSString *)key withValue
                  : (NSString *)value resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSData *dataFromValue = [value dataUsingEncoding:NSUTF8StringEncoding];

    if (dataFromValue == nil) {
        NSError *error =
            [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                code:0
                            userInfo:nil];
      [self rejectPromise:@"An error occured while saving value" error:error reject:reject];
        return;
    }

    // Prepares the insert query structure
    NSDictionary *storeQuery = @{
        (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount : key,
        (__bridge id)kSecValueData : dataFromValue
    };

    // Deletes the existing item prior to inserting the new one
    SecItemDelete((__bridge CFDictionaryRef)storeQuery);

    OSStatus insertStatus =
        SecItemAdd((__bridge CFDictionaryRef)storeQuery, nil);

    if (insertStatus == noErr) {
        resolve(value);
    }

    else {
        NSError *error =
            [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                code:insertStatus
                            userInfo:nil];
      [self rejectPromise:@"An error occured while saving value" error:error reject:reject];
    }
}

RCT_EXPORT_METHOD(getItem
                  : (NSString *)key resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSDictionary *getQuery = @{
        (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount : key,
        (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue,
        (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne
    };

    CFTypeRef dataRef = NULL;
    OSStatus getStatus =
        SecItemCopyMatching((__bridge CFDictionaryRef)getQuery, &dataRef);

    if (getStatus == errSecSuccess) {
        NSString *storedValue =
            [[NSString alloc] initWithData:(__bridge NSData *)dataRef
                                  encoding:NSUTF8StringEncoding];
        resolve(storedValue);
    }

    else if (getStatus == errSecItemNotFound) {
        resolve(nil);
    }

    else {
        NSError *error =
            [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                code:getStatus
                            userInfo:nil];
        [self rejectPromise:@"An error occured while retrieving value" error:error reject:reject];
    }
}

RCT_EXPORT_METHOD(removeItem
                  : (NSString *)key resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    NSDictionary *removeQuery = @{
        (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount : key,
        (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue
    };

    OSStatus removeStatus =
        SecItemDelete((__bridge CFDictionaryRef)removeQuery);

    if (removeStatus == noErr || removeStatus == errSecItemNotFound) {
        resolve(key);
    }

    else {
        NSError *error =
            [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                code:removeStatus
                            userInfo:nil];
        [self rejectPromise:@"An error occured while removing value" error:error reject:reject];
    }
}

RCT_EXPORT_SYNCHRONOUS_TYPED_METHOD(void, clear) {
    NSArray *secItemClasses = @[
        (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecClassInternetPassword,
        (__bridge id)kSecClassCertificate, (__bridge id)kSecClassKey,
        (__bridge id)kSecClassIdentity
    ];

    // Maps through all Keychain classes and deletes all items that match
    for (id secItemClass in secItemClasses) {
        NSDictionary *spec = @{(__bridge id)kSecClass : secItemClass};
        SecItemDelete((__bridge CFDictionaryRef)spec);
    }
}

- (NSDictionary *) constantsToExport
{
  return @{ @"IS_ENCRYPTED": @true }; // iOS always is
}

@end
