//
//  ReactHostHelper.h
//  MendixNative
//
//  Created by Yogendra Shelke on 13/05/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReactHostHelper : NSObject

- (nullable id) moduleForClass: (Class) clazz;
- (BOOL) isReactAppActive;
- (void) emitEvent: (nonnull NSString*) eventName payload: (nullable id) payload;

@end

NS_ASSUME_NONNULL_END
