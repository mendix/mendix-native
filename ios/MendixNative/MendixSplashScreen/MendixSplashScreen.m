//
//  Copyright (c) Mendix, Inc. All rights reserved.
//
#import "ReactNative.h"
#import "RNSplashScreen.h"

@interface MendixSplashScreen : NSObject<RCTBridgeModule>
@end

@implementation MendixSplashScreen

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(show) {
  [ReactNative.instance showSplashScreen];
}

RCT_EXPORT_METHOD(hide) {
  [ReactNative.instance hideSplashScreen];
}

@end
