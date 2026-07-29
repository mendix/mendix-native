//
//  ReactHostHelper.mm
//  MendixNative
//
//  Created by Yogendra Shelke on 13/05/26.
//

#import "ReactHostHelper.h"
#import <ReactCommon/RCTHost.h>
#import <React/RCTReloadCommand.h>
#import "RCTDefaultReactNativeFactoryDelegate.h"
#import "RCTReactNativeFactory.h"
#import "MendixNative-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ReactHostHelper

- (nullable id) moduleForClass: (Class) clazz {
    if ([NSThread isMainThread]) {
        return [self getModuleForClass: clazz];
    } else {
        __block id result;
        dispatch_sync(dispatch_get_main_queue(), ^{
            result = [self getModuleForClass: clazz];
        });
        return result;
    }
}

- (nullable id) getModuleForClass: (Class) clazz {
    RCTHost *reactHost = [self currentHost];
    RCTModuleRegistry *moduleRegistry = [reactHost moduleRegistry];
    id nativeModule = [moduleRegistry moduleForClass: clazz];
    return nativeModule;
}

- (RCTHost *) currentHost {
    ReactAppProvider *reactAppProvider = (ReactAppProvider *) [[UIApplication sharedApplication] delegate];
    RCTReactNativeFactory *reactNativeFactory = [reactAppProvider reactNativeFactory];
    RCTRootViewFactory *rootViewFactory = [reactNativeFactory rootViewFactory];
    RCTHost *reactHost = [rootViewFactory reactHost];
    return reactHost;
}

- (BOOL)isReactAppActive {
    if ([NSThread isMainThread]) {
        return [self currentHost] != nil;
    } else {
        __block bool result;
        dispatch_sync(dispatch_get_main_queue(), ^{
            result = [self currentHost] != nil;
        });
        return result;
    }
}

- (void)emitEvent:(nonnull NSString *)eventName payload:(nullable id)payload {
    RCTHost *reactHost = [self currentHost];
    
    NSMutableArray *args = [NSMutableArray arrayWithObject:eventName];
    if (payload != nil) {
        [args addObject:payload];
    }
    
    [reactHost callFunctionOnJSModule:@"RCTDeviceEventEmitter" method:@"emit" args:args];
}

@end

NS_ASSUME_NONNULL_END
