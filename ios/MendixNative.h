#import <MendixNativeSpec/MendixNativeSpec.h>
#import <React/RCTReloadCommand.h>
#import "RNCAsyncStorage.h"

@interface MendixNative : NativeMendixNativeSpecBase <NativeMendixNativeSpec>
- (void)reloadClientWithState;
@end
