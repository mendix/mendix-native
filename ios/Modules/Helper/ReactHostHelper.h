//
//  ReactHostHelper.h
//  MendixNative
//
//  Created by Yogendra Shelke on 13/05/26.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

NS_ASSUME_NONNULL_BEGIN

// RCTHost.h includes C++ headers, so Swift cannot reach the host directly.
// This exposes only its module registry, which is plain Objective-C.
@interface ReactHostHelper : NSObject

// Imported into Swift as @MainActor.
+ (nullable RCTModuleRegistry *) currentModuleRegistry NS_SWIFT_UI_ACTOR;

@end

NS_ASSUME_NONNULL_END
