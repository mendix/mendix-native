//
//  Copyright (c) Mendix, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@interface MendixEncryptedStorageModule : NSObject <RCTBridgeModule>

// These are the internal methods that the singleton backend will implement.
- (void)internal_setItem:(NSString *)key
               withValue:(NSString *)value
                resolver:(RCTPromiseResolveBlock)resolve
                rejecter:(RCTPromiseRejectBlock)reject;

- (void)internal_getItem:(NSString *)key
               resolver:(RCTPromiseResolveBlock)resolve
               rejecter:(RCTPromiseRejectBlock)reject;

- (void)internal_removeItem:(NSString *)key
                   resolver:(RCTPromiseResolveBlock)resolve
                   rejecter:(RCTPromiseRejectBlock)reject;

@end

@interface MendixEncryptedStorageModule (Private)
-(void) rejectPromise:(NSString *) message error:(NSError *)error reject:(RCTPromiseRejectBlock) rejecter;
@end
