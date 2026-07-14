#import "ObjCExceptionCatcher.h"

@implementation ObjCExceptionCatcher

+ (nullable id)catchException:(id _Nullable (NS_NOESCAPE ^)(void))block {
    @try {
        return block();
    } @catch (NSException *exception) {
        NSLog(@"ObjCExceptionCatcher: caught %@ — %@", exception.name, exception.reason);
        return nil;
    }
}

@end
