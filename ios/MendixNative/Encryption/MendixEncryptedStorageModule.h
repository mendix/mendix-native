//
//  Copyright (c) Mendix, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@interface MendixEncryptedStorageModule : NSObject <RCTBridgeModule>

@end

@interface MendixEncryptedStorageModule (Private)
-(void) rejectPromise:(NSString *) message error:(NSError *)error reject:(RCTPromiseRejectBlock) rejecter;
@end
