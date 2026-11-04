//
//  ReactHostHelper.mm
//  MendixNative
//
//  Created by Yogendra Shelke on 13/05/26.
//

#import "ReactHostHelper.h"
#import <ReactCommon/RCTHost.h>
// RCTReloadListener and RCTDefaultReactNativeFactoryDelegate are referenced by MendixNative-Swift.h.
#import <React/RCTReloadCommand.h>
#import "RCTDefaultReactNativeFactoryDelegate.h"
#import "RCTReactNativeFactory.h"
#import "MendixNative-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ReactHostHelper

+ (nullable RCTModuleRegistry *) currentModuleRegistry {
    RCTHost *reactHost = [[[[ReactAppProvider shared] reactNativeFactory] rootViewFactory] reactHost];
    return [reactHost moduleRegistry];
}

@end

NS_ASSUME_NONNULL_END
