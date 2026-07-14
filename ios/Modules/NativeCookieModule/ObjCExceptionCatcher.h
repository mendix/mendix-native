#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ObjCExceptionCatcher : NSObject

/// Executes the block and returns its result. If an NSException is raised,
/// catches it and returns nil instead of crashing.
+ (nullable id)catchException:(id _Nullable (NS_NOESCAPE ^)(void))block;

@end

NS_ASSUME_NONNULL_END
