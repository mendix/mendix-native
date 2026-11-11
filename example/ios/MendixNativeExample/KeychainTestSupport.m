#if DEBUG
#import <React/RCTBridgeModule.h>
#import <Security/Security.h>

@interface KeychainTestSupport : NSObject <RCTBridgeModule>
@end

@implementation KeychainTestSupport
RCT_EXPORT_MODULE()

+ (BOOL)requiresMainQueueSetup { return NO; }

RCT_EXPORT_METHOD(seedLegacyItem:(NSString *)key
                  value:(NSString *)value
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    NSDictionary *identity = @{
        (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrAccount: key
    };
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)identity);
    if (status != errSecSuccess && status != errSecItemNotFound) {
        reject([NSString stringWithFormat:@"%d", (int)status], @"Failed to remove test item", nil);
        return;
    }
    NSMutableDictionary *attributes = [identity mutableCopy];
    attributes[(__bridge NSString *)kSecValueData] = [value dataUsingEncoding:NSUTF8StringEncoding];
    attributes[(__bridge NSString *)kSecAttrAccessible] = (__bridge NSString *)kSecAttrAccessibleWhenUnlocked;
    status = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
    if (status != errSecSuccess) {
        reject([NSString stringWithFormat:@"%d", (int)status], @"Failed to seed test item", nil);
        return;
    }
    resolve(nil);
}

RCT_EXPORT_METHOD(inspectItem:(NSString *)key
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    NSDictionary *query = @{
        (__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrAccount: key,
        (__bridge NSString *)kSecReturnAttributes: @YES,
        (__bridge NSString *)kSecMatchLimit: (__bridge NSString *)kSecMatchLimitOne,
        (__bridge NSString *)kSecUseAuthenticationUI: (__bridge NSString *)kSecUseAuthenticationUIFail
    };
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecItemNotFound) {
        resolve(nil);
        return;
    }
    if (status != errSecSuccess) {
        reject([NSString stringWithFormat:@"%d", (int)status], @"Failed to inspect test item", nil);
        return;
    }
    NSDictionary *attributes = CFBridgingRelease(result);
    resolve(@{
        @"accessibility": attributes[(__bridge NSString *)kSecAttrAccessible],
        @"expectedAccessibility": (__bridge NSString *)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        @"legacyAccessibility": (__bridge NSString *)kSecAttrAccessibleWhenUnlocked
    });
}
@end
#endif
