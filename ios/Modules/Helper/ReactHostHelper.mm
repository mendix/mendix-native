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
#import "MxReload.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ReactHostHelper

- (nullable id)moduleForName:(nonnull NSString*)name {
    if ([NSThread isMainThread]) {
        return [self getModuleForName: name];
    } else {
        __block id result;
        dispatch_sync(dispatch_get_main_queue(), ^{
            result = [self getModuleForName: name];
        });
        return result;
    }
}

- (nullable id) getModuleForName:(nonnull NSString*)name {
    RCTHost *reactHost = [self currentHost];
    RCTModuleRegistry *moduleRegistry = [reactHost moduleRegistry];
    id nativeModule = [moduleRegistry moduleForName: name.UTF8String];
    return nativeModule;
}

- (RCTHost *) currentHost {
    ReactAppProvider *reactAppProvider = (ReactAppProvider *) [[UIApplication sharedApplication] delegate];
    RCTReactNativeFactory *reactNativeFactory = [reactAppProvider reactNativeFactory];
    RCTRootViewFactory *rootViewFactory = [reactNativeFactory rootViewFactory];
    RCTHost *reactHost = [rootViewFactory reactHost];
    return reactHost;
}


- (void) reloadClientWithState {
    MxReload *mxReload = [self moduleForName: MxReload.moduleName];
    [mxReload emitOnReloadWithState];
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

@end

NS_ASSUME_NONNULL_END
